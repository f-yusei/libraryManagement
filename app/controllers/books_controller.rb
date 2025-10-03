class BooksController < ApplicationController
  allow_unauthenticated_access only: %i[index show]
  admin_only only: %i[create new]
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
    Book.transaction do
      @book = Book.new(book_params)
      # ここで著者がパラメータに含まれていなかった時点でunprocessable_entityを返す
      if params[:author_names].blank?
        @book.errors.add(:authors, "を入力してください")
        render :new, status: :unprocessable_entity
        return
      end
      params[:author_names].split(",").map(&:strip).each do |name|
        author = Author.find_or_create_by!(name: name)
        @book.authors << author
      end

      if @book.save
        redirect_to @book, flash: { success: "本の登録が完了しました。" }
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  private

  def book_params
    params.require(:book).permit(:title, :isbn, :published_year, :publisher, :stock_count, :author_names)
  end
end
