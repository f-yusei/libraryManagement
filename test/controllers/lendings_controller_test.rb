require "test_helper"

class LendingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two)
    @book = books(:two)
    sign_in_as(@user)
  end

  test "creates a lending and redirects to the book with a success flash" do
    post lendings_path, params: { book_id: @book.id }
    assert_redirected_to book_path(@book)
    assert_equal "本の貸出が完了しました。", flash[:success]

    # 作成されたlendingの確認
    lending = Lending.last
    assert_equal @user.id, lending.user_id
    assert_equal @book.id, lending.book_id
    assert_nil lending.returned_at
  end

  test "redirects back with danger flash when out of stock" do
    @book.update!(stock_count: 0)

    post lendings_path, params: { book_id: @book.id }
    assert_redirected_to book_path(@book)
    assert_equal "在庫がありません。", flash[:danger]
  end
end
