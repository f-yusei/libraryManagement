class LendingsController < ApplicationController
  def create
    book = Book.find_by(params[:book_id])
    lending = lend_to(current_user, book)
    redirect_to book, success: "本の貸出が完了しました。"
  end
end
