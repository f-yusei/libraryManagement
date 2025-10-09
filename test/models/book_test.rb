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

  # 著者設定のテスト
  test "assign_authors creates new authors" do
    book = Book.new(title: "Test Book", isbn: "978-1234567890")

    assert_difference("Author.count", 2) do
      book.assign_authors("山田太郎,佐藤花子")
    end

    assert_equal 2, book.authors.size
    assert_includes book.authors.map(&:name), "山田太郎"
    assert_includes book.authors.map(&:name), "佐藤花子"
  end

  test "assign_authors finds existing authors" do
    existing_author = Author.create!(name: "既存著者")
    book = Book.new(title: "Test Book", isbn: "978-1234567890")

    assert_no_difference("Author.count") do
      book.assign_authors("既存著者")
    end

    assert_equal 1, book.authors.size
    assert_equal existing_author, book.authors.first
  end

  test "assign_authors handles duplicate names" do
    book = Book.new(title: "Test Book", isbn: "978-1234567890")

    assert_difference("Author.count", 1) do
      book.assign_authors("重複著者,重複著者,重複著者")
    end

    assert_equal 1, book.authors.size
    assert_equal "重複著者", book.authors.first.name
  end

  test "assign_authors strips whitespace" do
    book = Book.new(title: "Test Book", isbn: "978-1234567890")

    book.assign_authors("  山田太郎  , 佐藤花子 ")

    assert_equal 2, book.authors.size
    assert_includes book.authors.map(&:name), "山田太郎"
    assert_includes book.authors.map(&:name), "佐藤花子"
  end

  test "assign_authors ignores blank entries" do
    book = Book.new(title: "Test Book", isbn: "978-1234567890")

    book.assign_authors("山田太郎,,, ,佐藤花子")

    assert_equal 2, book.authors.size
    assert_includes book.authors.map(&:name), "山田太郎"
    assert_includes book.authors.map(&:name), "佐藤花子"
  end

  # タグ設定のテスト
  test "assign_tags creates new tags" do
    book = Book.new(title: "Test Book", isbn: "978-1234567890")

    assert_difference("Tag.count", 2) do
      book.assign_tags("プログラミング,技術書")
    end

    assert_equal 2, book.tags.size
    assert_includes book.tags.map(&:name), "プログラミング"
    assert_includes book.tags.map(&:name), "技術書"
  end

  test "assign_tags finds existing tags" do
    existing_tag = Tag.create!(name: "既存タグ")
    book = Book.new(title: "Test Book", isbn: "978-1234567890")

    assert_no_difference("Tag.count") do
      book.assign_tags("既存タグ")
    end

    assert_equal 1, book.tags.size
    assert_equal existing_tag, book.tags.first
  end

  test "assign_tags clears tags when empty string" do
    book = books(:one)
    # 既存のタグを設定
    book.assign_tags("Ruby,Rails")
    assert_equal 2, book.tags.size

    # 空文字列で全タグをクリア
    book.assign_tags("")
    assert_equal 0, book.tags.size
  end

  test "assign_tags clears tags when nil" do
    book = books(:one)
    # 既存のタグを設定
    book.assign_tags("Ruby,Rails")
    assert_equal 2, book.tags.size

    # nilで全タグをクリア
    book.assign_tags(nil)
    assert_equal 0, book.tags.size
  end

  test "assign_tags handles whitespace and duplicates" do
    book = Book.new(title: "Test Book", isbn: "978-1234567890")

    book.assign_tags("  Ruby  , Rails ,  , Ruby ")

    assert_equal 2, book.tags.size
    assert_includes book.tags.map(&:name), "Ruby"
    assert_includes book.tags.map(&:name), "Rails"
  end

  # バリデーションのテスト
  test "validates presence of authors" do
    book = Book.new(title: "Test Book", isbn: "978-1234567890")
    book.author_names_string = ""

    assert_not book.valid?
    assert_includes book.errors[:authors], "を入力してください"
  end

  test "validates authors when author_names_string has only whitespace" do
    book = Book.new(title: "Test Book", isbn: "978-1234567890")
    book.author_names_string = "  ,  ,  "

    assert_not book.valid?
    assert_includes book.errors[:authors], "を入力してください"
  end

  test "does not require tags for validation" do
    book = Book.new(title: "Test Book", isbn: "978-1234567890", stock_count: 1)

    # 著者を設定してからバリデーション
    book.assign_authors("テスト著者")

    assert book.save
    assert_equal 1, book.authors.size
    assert_equal 0, book.tags.size
  end

  test "valid book with proper authors" do
    book = Book.new(title: "Test Book", isbn: "978-1234567890")
    book.author_names_string = "著者名"

    assert_not book.valid?
  end
end
