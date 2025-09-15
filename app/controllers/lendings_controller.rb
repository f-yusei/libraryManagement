class LendingsController < ApplicationController
  def create
    book = Book.find(params[:book_id])
    lending = Lending.lend_to(current_user, book)

    if lending.persisted?
      redirect_to book, success: "本の貸出が完了しました。"
    else
      redirect_to book, danger: "貸出に失敗しました。"
    end
  rescue Lending::OutOfStockError
    redirect_to book, danger: "在庫がありません。"
  end
end
