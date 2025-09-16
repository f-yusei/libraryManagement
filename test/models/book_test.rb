require "test_helper"

class BookTest < ActiveSupport::TestCase
  test "search finds books by title, isbn, or author name" do
    book = books(:one)
    assert_includes Book.search(book.title), book
    assert_includes Book.search(book.isbn), book
    assert_includes Book.search(book.authors.first.name), book
  end

  test "search with blank query returns all books" do
    assert_equal Book.count, Book.search(nil).count
    assert_equal Book.count, Book.search("").count
  end

  test "search returns empty when no matches" do
    assert_empty Book.search("Nonexistent Title")
  end
end
