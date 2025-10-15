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

    # 個別に設定
    @book.assign_authors(params[:author_names]) if params[:author_names].present?
    @book.assign_tags(params[:tag_names]) if params[:tag_names].present?

    if @book.save
      redirect_to @book, flash: { success: "本の登録が完了しました。" }
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    book = Book.find_by(id: params[:id])

    if book.nil?
      redirect_to root_path, flash: { danger: "本が見つかりません" }
      return
    end

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
