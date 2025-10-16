require "http"
require "json"

class GoogleBooksService
  # Google Books API のベースURL
  BASE_URL = ENV.fetch("GOOGLE_BOOKS_API_URL", "https://www.googleapis.com/books/v1/volumes")

  # API接続のタイムアウト時間（秒）
  TIMEOUT_SECONDS = 10

  # クラスメソッド: ISBNで書籍を検索
  # @param isbn [String] 検索するISBN
  # @return [Hash] { success: true/false, data: {}, error: "" }
  class << self
    def search_by_isbn(isbn)
      new.search_by_isbn(isbn)
    end
  end

  # インスタンスメソッド: ISBNで書籍を検索
  # @param isbn [String] 検索するISBN
  # @return [Hash] 成功: { success: true, data: { isbn:, title:, authors:, publisher:, published_year:, image_url:, description: } }
  #                失敗: { success: false, error: "エラーメッセージ" }
  def search_by_isbn(isbn)
    # 1. ISBNを正規化（ハイフン削除、形式チェック）
    normalized_isbn = normalize_isbn(isbn)
    # 2. Google Books APIにリクエスト送信
    response = fetch_book_data(normalized_isbn)
    # 3. レスポンスをパースして結果を返す
    parsed_response = parse_response(response, normalized_isbn)
    # 4. エラーハンドリング（HTTP エラー等）
    if parsed_response.success?
      { success: true, data: parsed_response }
    else
      { success: false, error: parsed_response[:error] }
    end
  end

  private

  # ISBNの正規化処理
  # @param isbn [String] 入力ISBN
  # @return [String, nil] 正規化されたISBN または nil（無効な場合）
  def normalize_isbn(isbn)
    # 1. 空白・nil チェック
    if isbn.blank?
      return nil
    end
    # 2. ハイフンと空白を除去
    clean_isbn = isbn.delete("- ").strip
    # 3. ISBN-10（10桁）またはISBN-13（13桁）の数字のみかチェック
    if clean_isbn.match?(/\A\d{10}\z/) || clean_isbn.match?(/\A\d{13}\z/)
      return clean_isbn
    end
    # 4. 有効な場合は clean_isbn を返す、無効な場合は nil を返す
    nil
  end

  # Google Books APIからデータを取得
  # @param isbn [String] 正規化済みISBN
  # @return [Hash] APIレスポンスのJSON
  def fetch_book_data(isbn)
    # 1. HTTPリクエスト送信
    response = HTTP.timeout(TIMEOUT_SECONDS).get("#{BASE_URL}?q=isbn:#{isbn}", headers: { "User-Agent" => "LibraryManagementApp/1.0" })
    # 2. レスポンスコードが200以外の場合はエラーを投げる
    unless response.status.success?
      raise "API request failed with status #{response.code}: #{response.body}"
    end
    # 3. JSONをパースして返す
    JSON.parse(response.body.to_s)
  end

  # APIレスポンスを解析
  # @param response [Hash] APIレスポンスのJSON
  # @param isbn [String] 検索に使用したISBN
  # @return [Hash] パース結果
  def parse_response(response, isbn)
    # 1. totalItems が 0 または nil の場合は「見つからない」エラー
    if response["totalItems"].to_i == 0
      return { error: "Book not found" }
    end
    # 2. items[0].volumeInfo を取得
    volume_info = response.dig("items", 0, "volumeInfo")
    # 3. volumeInfo が nil の場合は「取得失敗」エラー
    if volume_info.nil?
      return { error: "Failed to retrieve book information" }
    end
    # 4. 以下の情報を抽出してハッシュで返す:
    #    - isbn: 検索に使用したISBN
    #    - title: volumeInfo["title"]
    #    - authors: volumeInfo["authors"] || []
    #    - publisher: volumeInfo["publisher"]
    #    - published_year: extract_year() で抽出
    #    - image_url: extract_image_url() で抽出
    {
      isbn: isbn,
      title: volume_info["title"],
      authors: volume_info["authors"] || [],
      publisher: volume_info["publisher"],
      published_year: volume_info["publishedDate"],
      image_url: extract_image_url(volume_info["imageLinks"])
    }
  end

  # 画像URLを抽出（品質の高い順に優先）
  # @param image_links [Hash, nil] volumeInfo["imageLinks"]
  # @return [String, nil] 画像URL または nil
  def extract_image_url(image_links)
    # 1. image_links が nil の場合は nil を返す
    return nil if image_links.nil?
    # 2. 以下の優先順位で画像URLを選択:
    #    - "large"
    #    - "medium"
    #    - "thumbnail"
    #    - "smallThumbnail"
    # 3. 最初に見つかったものを返す
    %w[large medium thumbnail smallThumbnail].each do |size|
      return image_links[size] if image_links[size]
    end
    nil
  end
end
