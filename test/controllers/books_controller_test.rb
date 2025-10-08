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
end
