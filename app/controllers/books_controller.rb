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

      raw = params[:author_names].to_s
      names = raw.split(",").map { |s| s.strip }.reject(&:blank?).uniq

      if names.empty?
        @book.errors.add(:authors, "を入力してください")
        render :new, status: :unprocessable_entity
        return
      end

      ActiveRecord::Base.transaction do
        @book.save!
        authors = names.map { |name| Author.find_or_create_by!(name: name) }
        @book.authors << authors
      end

      redirect_to @book, flash: { success: "本の登録が完了しました。" }
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      flash.now[:alert] = "登録に失敗しました。 #{e.message}"
      render :new, status: :unprocessable_entity
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
