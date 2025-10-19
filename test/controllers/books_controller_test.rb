require "test_helper"

class BooksControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url
    assert_template "books/index"
    assert_response :success
  end

  test "destroy requires admin authentication" do
    book = books(:one)

    # 未ログインユーザー
    delete book_path(book)
    assert_redirected_to new_session_path

    # 一般ユーザー
    sign_in_as(users(:one))
    delete book_path(book)
    assert_redirected_to root_path
    assert_equal "アクセス権限がありません", flash[:danger]
  end

  test "destroy redirects with success when book can be destroyed" do
    book = books(:one)
    # 既存の貸出データをクリア
    book.lendings.destroy_all

    sign_in_as(users(:admin)) # 管理者でログイン

    assert_difference("Book.count", -1) do
      delete book_path(book)
    end

    assert_redirected_to root_path
    assert_equal "本の削除が完了しました。", flash[:success]
  end

  test "destroy redirects with error when book cannot be destroyed" do
    book = books(:one)
    user = users(:one)
    sign_in_as(users(:admin))

    # 貸出中にする
    Lending.create!(
      book: book,
      user: user,
      checked_out_at: Time.current,
      due_date: 2.weeks.from_now,
      returned_at: nil
    )

    assert_no_difference("Book.count") do
      delete book_path(book)
    end

    assert_redirected_to root_path
    assert_equal "貸出中の本は削除できません", flash[:danger]
  end

  # 書籍作成のテスト
  test "create requires admin authentication" do
    # 未ログインユーザー
    post books_path, params: {
      book: { title: "Test", isbn: "123", stock_count: 1 },
      author_names: "著者名"
    }
    assert_redirected_to new_session_path

    # 一般ユーザー
    sign_in_as(users(:one))
    post books_path, params: {
      book: { title: "Test", isbn: "123", stock_count: 1 },
      author_names: "著者名"
    }
    assert_redirected_to root_path
    assert_equal "アクセス権限がありません", flash[:danger]
  end

  test "creates book with authors and tags" do
    sign_in_as(users(:admin))

    assert_difference("Book.count", 1) do
      assert_difference("Author.count", 2) do
        assert_difference("Tag.count", 2) do
          post books_path, params: {
            book: {
              title: "新しい本",
              isbn: "978-1234567890",
              publisher: "テスト出版",
              stock_count: 5
            },
            author_names: "山田太郎,佐藤花子",
            tag_names: "プログラミング,技術書"
          }
        end
      end
    end

    book = Book.last
    assert_redirected_to book_path(book)
    assert_equal "本の登録が完了しました。", flash[:success]

    # 著者の確認
    assert_equal 2, book.authors.size
    assert_includes book.authors.map(&:name), "山田太郎"
    assert_includes book.authors.map(&:name), "佐藤花子"

    # タグの確認
    assert_equal 2, book.tags.size
    assert_includes book.tags.map(&:name), "プログラミング"
    assert_includes book.tags.map(&:name), "技術書"
  end

  test "creates book with authors only (no tags)" do
    sign_in_as(users(:admin))

    assert_difference("Book.count", 1) do
      assert_difference("Author.count", 1) do
        assert_no_difference("Tag.count") do
          post books_path, params: {
            book: {
              title: "タグなし本",
              isbn: "978-0987654321",
              stock_count: 3
            },
            author_names: "著者のみ"
            # tag_names は送信しない
          }
        end
      end
    end

    book = Book.last
    assert_equal 1, book.authors.size
    assert_equal "著者のみ", book.authors.first.name
    assert_equal 0, book.tags.size
  end

  test "fails to create book without authors" do
    sign_in_as(users(:admin))

    assert_no_difference("Book.count") do
      assert_no_difference("Author.count") do
        post books_path, params: {
          book: {
            title: "著者なし本",
            isbn: "978-1111111111",
            stock_count: 1
          }
          # author_names を送信しない
        }
      end
    end

    assert_response :unprocessable_entity
    assert_template :new
  end

  test "fails to create book with empty authors" do
    sign_in_as(users(:admin))

    assert_no_difference("Book.count") do
      assert_no_difference("Author.count") do
        post books_path, params: {
          book: {
            title: "空著者本",
            isbn: "978-2222222222",
            stock_count: 1
          },
          author_names: "  ,  ,  " # 空白のみ
        }
      end
    end

    assert_response :unprocessable_entity
    assert_template :new
  end

  test "creates book with existing authors and tags" do
    # 既存の著者とタグを作成
    existing_author = Author.create!(name: "既存著者")
    existing_tag = Tag.create!(name: "既存タグ")

    sign_in_as(users(:admin))

    assert_difference("Book.count", 1) do
      assert_no_difference([ "Author.count", "Tag.count" ]) do
        post books_path, params: {
          book: {
            title: "既存関連本",
            isbn: "978-3333333333",
            stock_count: 2
          },
          author_names: "既存著者",
          tag_names: "既存タグ"
        }
      end
    end

    book = Book.last
    assert_equal existing_author, book.authors.first
    assert_equal existing_tag, book.tags.first
  end

  test "GET /books/search_isbn returns turbo stream with search result" do
    sample_response = {
      isbn: "9781234567890",
      title: "Sample Title",
      authors: [ "Author One" ],
      publisher: "Sample Publisher",
      published_date: Date.new(2024, 1, 1),
      image_url: "https://example.com/thumb.jpg"
    }

    sign_in_as(users(:admin))

    GoogleBooksService.stub(:call, ->(_isbn) { sample_response }) do
      get search_isbn_books_path(isbn: sample_response[:isbn]), as: :turbo_stream
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", @response.media_type
    stream = css_select("turbo-stream[action='replace'][target='search_result']").first
    assert stream, "search_result turbo stream not rendered"

    fragment = Nokogiri::HTML::DocumentFragment.parse(stream.inner_html)
    assert_includes fragment.to_html, sample_response[:title]
    assert_includes fragment.to_html, sample_response[:authors].first
    assert_includes fragment.to_html, sample_response[:publisher]
    assert_includes fragment.to_html, sample_response[:isbn]
    assert_includes fragment.to_html, "登録する"

    form = fragment.at_css("form[action='#{create_from_isbn_books_path}']")
    assert form, "create_from_isbn form not found"
    assert_equal "_top", form["data-turbo-frame"]
  end

  test "GET /books/search_isbn renders not found partial when service raises" do
    sign_in_as(users(:admin))

    GoogleBooksService.stub(:call, ->(_isbn) { raise Exceptions::ExternalServiceRecordNotFoundError.new }) do
      get search_isbn_books_path(isbn: "9781234567890"), as: :turbo_stream
    end

    assert_response :success
    stream = css_select("turbo-stream[action='replace'][target='search_result']").first
    assert stream, "search_result turbo stream not rendered"

    fragment = Nokogiri::HTML::DocumentFragment.parse(stream.inner_html)
    assert_includes fragment.to_html, "検索結果が見つかりませんでした"
    assert_includes fragment.to_html, "9781234567890"
  end

  test "GET /books/search_isbn renders error partial when isbn blank" do
    sign_in_as(users(:admin))

    get search_isbn_books_path(isbn: ""), as: :turbo_stream

    assert_response :success
    stream = css_select("turbo-stream[action='replace'][target='search_result']").first
    assert stream, "search_result turbo stream not rendered"

    fragment = Nokogiri::HTML::DocumentFragment.parse(stream.inner_html)
    assert_includes fragment.to_html, "検索に失敗しました"
    assert_includes fragment.to_html, "ISBNを入力してください。"
  end

  test "POST /books/create_from_isbn registers book when valid" do
    sample_response = {
      isbn: "9781234567890",
      title: "Sample Title",
      authors: [ "Author One", "Author Two" ],
      publisher: "Sample Publisher",
      published_date: Date.new(2024, 5, 1)
    }

    sign_in_as(users(:admin))

    GoogleBooksService.stub(:call, ->(_isbn) { sample_response }) do
      assert_difference("Book.count", 1) do
        assert_difference("Author.count", 2) do
          post create_from_isbn_books_path,
               params: { isbn: sample_response[:isbn], stock_count: 3 },
               headers: { "Turbo-Frame" => "_top" }
        end
      end
    end

    book = Book.order(:created_at).last
    assert_redirected_to book_path(book)
    assert_equal "書籍が正常に登録されました。", flash[:success]
    assert_equal sample_response[:isbn], book.isbn
    assert_equal 3, book.stock_count
    assert_equal sample_response[:authors].sort, book.authors.pluck(:name).sort
  end

  test "POST /books/create_from_isbn rejects invalid stock count" do
    sign_in_as(users(:admin))

    GoogleBooksService.stub(:call, ->(_isbn) { flunk "GoogleBooksService should not be called" }) do
      post create_from_isbn_books_path,
           params: { isbn: "9781234567890", stock_count: 0 },
           headers: { "Turbo-Frame" => "_top" }
    end

    assert_response :unprocessable_entity
    assert_template :new
  assert_equal "在庫数は1以上の整数で入力してください。", flash[:alert]
  end

  test "POST /books/create_from_isbn rejects duplicate isbn" do
    sign_in_as(users(:admin))
    existing_isbn = books(:one).isbn

    GoogleBooksService.stub(:call, ->(_isbn) { flunk "GoogleBooksService should not be called" }) do
      post create_from_isbn_books_path,
           params: { isbn: "#{existing_isbn[0..2]}-#{existing_isbn[3..]}" },
           headers: { "Turbo-Frame" => "_top" }
    end

    assert_response :unprocessable_entity
    assert_template :new
  assert_equal "このISBNの書籍は既に登録されています。", flash[:alert]
  end

  test "POST /books/create_from_isbn handles service not found error" do
    sign_in_as(users(:admin))

    GoogleBooksService.stub(:call, ->(_isbn) { raise Exceptions::ExternalServiceRecordNotFoundError.new("見つかりませんでした") }) do
      post create_from_isbn_books_path,
           params: { isbn: "9781234567890", stock_count: 1 },
           headers: { "Turbo-Frame" => "_top" }
    end

    assert_response :not_found
    assert_template :new
    assert_equal "見つかりませんでした", flash[:alert]
  end
end
