class BooksController < ApplicationController
  allow_unauthenticated_access only: %i[index show]
  admin_only only: %i[create new destroy edit update create_from_isbn]
  PER_PAGE = 6
  SORT_OPTIONS = {
    "newest" => "新着順",
    "title_asc" => "タイトル（あいうえお順）",
    "published_desc" => "出版日が新しい順"
  }.freeze

  def index
    @sort_param = normalize_sort(params[:sort])
    @books = Book.search(params[:q])
                 .yield_self { |scope| apply_sort(scope, @sort_param) }
                 .page(params[:page])
                 .per(PER_PAGE)
    @sort_options = SORT_OPTIONS
  end

  def show
    @book = Book.find(params[:id])
  end

  def edit
    @book = Book.find(params[:id])
  end

  def update
    @book = Book.find(params[:id])
    @book.assign_attributes(book_params)
    @book.assign_authors(params[:author_names]) if params.key?(:author_names)
    @book.assign_tags(params[:tag_names]) if params.key?(:tag_names)

    if @book.save
      redirect_to @book, flash: { success: "書籍の情報を更新しました。" }
    else
      flash.now[:alert] = "書籍の更新に失敗しました。"
      render :edit, status: :unprocessable_entity
    end
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

  def search_isbn
    @isbn = params[:isbn].to_s.strip
    raise Exceptions::ValidationError.new("ISBNを入力してください。") if @isbn.blank?

    book_info = GoogleBooksService.call(@isbn)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "search_result",
          partial: "books/search_result",
          locals: { book_info: book_info }
        )
      end
      format.html do
        @book = Book.new
        @book_info = book_info
        render :new
      end
    end
  rescue Exceptions::ExternalServiceRecordNotFoundError => e
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "search_result",
          partial: "books/search_not_found",
          locals: { isbn: @isbn }
        )
      end
      format.html do
        @book = Book.new
        flash.now[:alert] = e.message
        render :new, status: :not_found
      end
    end
  rescue Exceptions::ApplicationError => e
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "search_result",
          partial: "books/search_error",
          locals: { error_message: e.message }
        )
      end
      format.html do
        @book = Book.new
        flash.now[:alert] = e.message
        render :new, status: e.status
      end
    end
  end

  def create_from_isbn
    @isbn = params[:isbn].to_s.strip
    validate_isbn_presence!
    stock_count = extract_stock_count(params[:stock_count])
    ensure_book_not_registered!(@isbn)

    book_info = GoogleBooksService.call(@isbn)
    @book = build_book_from_info(book_info, stock_count: stock_count)

    if @book.save
      redirect_to @book, flash: { success: "書籍が正常に登録されました。" }
    else
      @book_info = book_info
      render :new, status: :unprocessable_entity
    end
  rescue Exceptions::ExternalServiceRecordNotFoundError => e
    handle_isbn_registration_error(e.message, :not_found)
  rescue Exceptions::ApplicationError => e
    handle_isbn_registration_error(e.message, e.status)
  end

  private

  def normalize_sort(raw_sort)
    sort_value = raw_sort.to_s
    SORT_OPTIONS.key?(sort_value) ? sort_value : "newest"
  end

  def apply_sort(scope, sort_key)
    case sort_key
    when "title_asc"
      scope.reorder(title_sort_order)
    when "published_desc"
      scope.reorder(published_date: :desc, created_at: :desc)
    else
      scope.reorder(created_at: :desc)
    end
  end

  def title_sort_order
    if postgresql_adapter?
      Arel.sql('title COLLATE "ja-x-icu" ASC, id ASC')
    else
      { title: :asc, id: :asc }
    end
  end

  def postgresql_adapter?
    ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
  end

  def validate_isbn_presence!
    return if @isbn.present?

    raise Exceptions::ValidationError.new("ISBNを入力してください。")
  end

  def extract_stock_count(raw_stock_count)
    return 1 if raw_stock_count.blank?

    stock_count = Integer(raw_stock_count, 10)
    raise Exceptions::ValidationError.new("在庫数は1以上の整数で入力してください。") if stock_count < 1

    stock_count
  rescue ArgumentError
    raise Exceptions::ValidationError.new("在庫数は1以上の整数で入力してください。")
  end

  def ensure_book_not_registered!(isbn)
    normalized_isbn = isbn.to_s.delete("- ")
    return unless Book.exists?(isbn: normalized_isbn)

    raise Exceptions::ValidationError.new("このISBNの書籍は既に登録されています。")
  end

  def build_book_from_info(book_info, stock_count:)
    author_names = Array(book_info[:authors]).reject(&:blank?).join(", ")
    Book.new(
      title: book_info[:title],
      isbn: book_info[:isbn],
      published_date: book_info[:published_date],
      publisher: book_info[:publisher],
      stock_count: stock_count
    ).tap do |book|
      book.assign_authors(author_names) if author_names.present?
    end
  end

  def handle_isbn_registration_error(message, status)
    @book = Book.new
    @book_info ||= { isbn: @isbn }
    flash.now[:alert] = message
    render :new, status: status
  end

  def book_params
    params.require(:book).permit(:title, :isbn, :published_date, :publisher, :stock_count)
  end
end
