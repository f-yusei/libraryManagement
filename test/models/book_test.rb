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

  test "can be destroyed when no unreturned lendings" do
    book = books(:one)
    # 既存の貸出データをクリア
    book.lendings.destroy_all

    assert book.can_be_destroyed?
    assert book.destroy
  end

  test "cannot be destroyed when has unreturned lendings" do
    book = books(:one)
    user = users(:one)

    # 貸出を作成（returned_atをnilにして未返却にする）
    Lending.create!(
      book: book,
      user: user,
      checked_out_at: Time.current,
      due_date: 2.weeks.from_now,
      returned_at: nil
    )

    assert_not book.can_be_destroyed?
    assert_not book.destroy
    assert_includes book.errors[:base], "貸出中の本は削除できません"
  end
end
