class Lending < ApplicationRecord
  belongs_to :book
  belongs_to :user

  class OutOfStockError < StandardError; end

  def self.lend_to(user, book)
    raise OutOfStockError, "在庫がありません" if book.stock_count <= 0

    transaction do
      create!(user: user, book: book, checked_out_at: Time.current, due_date: 2.weeks.from_now).tap do
        book.decrement!(:stock_count)
      end
    end
  end

  def return!
    transaction do
      book.increment!(:stock_count)
      update!(returned_at: Time.current)
    end
  end
end
