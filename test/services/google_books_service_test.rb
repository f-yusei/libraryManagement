# frozen_string_literal: true

require "test_helper"
require "date"

class GoogleBooksServiceTest < ActiveSupport::TestCase
  test "call raises validation error when isbn is invalid" do
    error = assert_raises(Exceptions::ValidationError) do
      GoogleBooksService.call("abc")
    end

    assert_equal "ISBNが無効です。", error.message
  end

  test "call returns parsed payload when book info is found" do
    sample_response = {
      "totalItems" => 1,
      "items" => [
        {
          "volumeInfo" => {
            "title" => "Practical Rails",
            "authors" => [ "Taro Yamada" ],
            "publisher" => "Sample Publisher",
            "publishedDate" => "2024",
            "imageLinks" => { "thumbnail" => "https://example.com/thumb.jpg" }
          }
        }
      ]
    }

    service_class = Class.new(GoogleBooksService) do
      define_method(:fetch_book_data) { |_| sample_response }
    end

    result = service_class.new("978-1234567890").call

    assert_equal "9781234567890", result[:isbn]
    assert_equal "Practical Rails", result[:title]
    assert_equal [ "Taro Yamada" ], result[:authors]
  assert_equal "Sample Publisher", result[:publisher]
  assert_equal Date.new(2024, 1, 1), result[:published_date]
    assert_equal "https://example.com/thumb.jpg", result[:image_url]
  end

  test "call raises record not found when no items returned" do
    service_class = Class.new(GoogleBooksService) do
      define_method(:fetch_book_data) { |_| { "totalItems" => 0, "items" => [] } }
    end

    error = assert_raises(Exceptions::ExternalServiceRecordNotFoundError) do
      service_class.new("9781234567890").call
    end

    assert_equal "該当する書籍が見つかりませんでした。", error.message
  end

  test "call raises external service error when response missing volume info" do
    service_class = Class.new(GoogleBooksService) do
      define_method(:fetch_book_data) { |_| { "totalItems" => 1, "items" => [ { "volumeInfo" => nil } ] } }
    end

    error = assert_raises(Exceptions::ExternalServiceError) do
      service_class.new("9781234567890").call
    end

    assert_equal "書籍情報の取得に失敗しました。", error.message
  end

  test "call raises external service error when title missing" do
    service_class = Class.new(GoogleBooksService) do
      define_method(:fetch_book_data) do |_|
        {
          "totalItems" => 1,
          "items" => [ { "volumeInfo" => { "title" => " ", "authors" => [ "Foo" ] } } ]
        }
      end
    end

    error = assert_raises(Exceptions::ExternalServiceError) do
      service_class.new("9781234567890").call
    end

    assert_equal "書籍タイトルの取得に失敗しました。", error.message
  end

  test "call raises external service error when authors missing" do
    service_class = Class.new(GoogleBooksService) do
      define_method(:fetch_book_data) do |_|
        {
          "totalItems" => 1,
          "items" => [ { "volumeInfo" => { "title" => "Practical Rails", "authors" => [] } } ]
        }
      end
    end

    error = assert_raises(Exceptions::ExternalServiceError) do
      service_class.new("9781234567890").call
    end

    assert_equal "書籍の著者情報の取得に失敗しました。", error.message
  end
end
