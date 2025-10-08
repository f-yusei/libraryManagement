class BooksController < ApplicationController
  allow_unauthenticated_access only: %i[index show]
  admin_only only: %i[create new destroy]
  def index
    @books = Book.search(params[:q])
  end

  def show
    @book = Book.find(params[:id])
  end

  def edit
    @book = Book.find(params[:id])
  end

  def new
    @book = Book.new
  end

  def create
    @book = Book.new(book_params)
    @book.assign_authors_from_string(params[:author_names])

    if @book.save
      redirect_to @book, flash: { success: "本の登録が完了しました。" }
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    book = Book.find(params[:id])

    if book.destroy
      redirect_to root_path, flash: { success: "本の削除が完了しました。" }
    else
      redirect_to root_path, flash: { danger: book.errors.full_messages.join(", ") }
    end
  end

  private

  def book_params
    params.require(:book).permit(:title, :isbn, :published_year, :publisher, :stock_count)
  end
end
