class Lending < ApplicationRecord
  belongs_to :book
  belongs_to :user

  class OutOfStockError < StandardError; end

  scope :unreturned, -> { where(returned_at: nil) }

  def self.lend_to(user, book)
    raise OutOfStockError, "在庫がありません" if book.stock_count <= 0

    transaction do
      lending = create!(user: user, book: book, checked_out_at: Time.current, due_date: 2.weeks.from_now)
      book.decrement!(:stock_count)
      lending
    end
  end

  def return!
    raise "既に返却済みです。" if returned_at.present?

    transaction do
      book.increment!(:stock_count)
      update!(returned_at: Time.current)
    end
  end
end
