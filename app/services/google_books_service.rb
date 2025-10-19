require "http"
require "json"
require "date"

class GoogleBooksService < BaseService
  BASE_URL = ENV.fetch("GOOGLE_BOOKS_API_URL", "https://www.googleapis.com/books/v1/volumes")

  class << self
    alias_method :search_by_isbn, :call
  end

  def initialize(isbn)
    @isbn = isbn
  end

  def call
    normalized_isbn = normalize_isbn(@isbn)
    raise Exceptions::ValidationError.new("ISBNが無効です。") if normalized_isbn.nil?

    response = fetch_book_data(normalized_isbn)
    parsed_response = parse_response(response, normalized_isbn)

    parsed_response
  rescue HTTP::TimeoutError, HTTP::Error => e
    raise Exceptions::ExternalServiceError.new("Google Books APIとの通信に失敗しました。(#{e.message})")
  end

  private

  def normalize_isbn(isbn)
    return nil if isbn.blank?

    clean_isbn = isbn.to_s.delete("- ").strip

    if clean_isbn.match?(/\A\d{10}\z/) || clean_isbn.match?(/\A\d{13}\z/)
      return clean_isbn
    end

    nil
  end

  def fetch_book_data(isbn)
    response = HTTP.timeout(connect: 0.5, write: 0.5, read: 1.5)
                   .get(BASE_URL, params: { "q" => "isbn:#{isbn}", "maxResults" => 1 },
                                 headers: { "User-Agent" => "LibraryManagementApp/1.0" })

    unless response.status.success?
      raise Exceptions::ExternalServiceError.new(
        "Google Books APIからエラーレスポンスが返されました。 status=#{response.code} body=#{response.body}"
      )
    end

    JSON.parse(response.body.to_s)
  end

  def parse_response(response, isbn)
    if response["totalItems"].to_i == 0
      raise Exceptions::ExternalServiceRecordNotFoundError.new("該当する書籍が見つかりませんでした。")
    end

    volume_info = response.dig("items", 0, "volumeInfo")

    if volume_info.nil?
      raise Exceptions::ExternalServiceError.new("書籍情報の取得に失敗しました。")
    end

    title = volume_info["title"].to_s.strip
    if title.blank?
      raise Exceptions::ExternalServiceError.new("書籍タイトルの取得に失敗しました。")
    end

    authors = Array(volume_info["authors"]).map { |author| author.to_s.strip }.reject(&:blank?).uniq
    if authors.empty?
      raise Exceptions::ExternalServiceError.new("書籍の著者情報の取得に失敗しました。")
    end

    {
      isbn: isbn,
      title: title,
      authors: authors,
      publisher: volume_info["publisher"].presence,
      published_date: parse_published_date(volume_info["publishedDate"]),
      image_url: extract_image_url(volume_info["imageLinks"])
    }
  end

  def extract_image_url(image_links)
    return nil if image_links.nil?

    %w[large medium thumbnail smallThumbnail].each do |size|
      return image_links[size] if image_links[size]
    end

    nil
  end

  def parse_published_date(value)
    return nil if value.blank?

    cleaned_value = value.to_s.strip

    case cleaned_value
    when /\A\d{4}\z/
      Date.new(cleaned_value.to_i, 1, 1)
    when /\A\d{4}-\d{2}\z/
      year, month = cleaned_value.split("-").map(&:to_i)
      Date.new(year, month, 1)
    when /\A\d{4}-\d{2}-\d{2}\z/
      year, month, day = cleaned_value.split("-").map(&:to_i)
      Date.new(year, month, day)
    else
      Date.parse(cleaned_value)
    end
  rescue ArgumentError, Date::Error
    nil
  end
end
