class LendingsController < ApplicationController
  def create
    book = Book.find(params[:book_id])
    lending = Lending.lend_to(current_user, book)

    if lending.persisted?
      redirect_to book, flash: { success: "本の貸出が完了しました。" }
    else
      redirect_to book, flash: { danger: "貸出に失敗しました。" }
    end
  rescue Lending::OutOfStockError
    redirect_to book, flash: { danger: "在庫がありません。" }
  end

  def destroy
    lending = current_user.lendings.unreturned.find(params[:id])
    book = lending.book

    lending.return!

  redirect_to book, flash: { success: "返却が完了しました。" }
  end
end
