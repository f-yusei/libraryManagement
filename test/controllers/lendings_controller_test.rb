require "test_helper"

class LendingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @book = books(:one)
    sign_in_as(@user)
  end

  test "creates a lending and redirects to the book with a success flash" do
    post lendings_path, params: { book_id: @book.id }
    assert_redirected_to book_path(@book)
    assert_equal "本の貸出が完了しました。", flash[:success]
  end

  test "redirects back with danger flash when out of stock" do
    @book.update!(stock_count: 0)

    post lendings_path, params: { book_id: @book.id }
    assert_redirected_to book_path(@book)
    assert_equal "在庫がありません。", flash[:danger]
  end

  test "redirects back with danger flash when lending fails to persist" do
    # createが失敗するように Book にバリデーションを仕掛けておくか、
    # Lending.lend_to を stub して `persisted?` を false にするのも手
    Lending.stub :lend_to, Lending.new do
      post lendings_path, params: { book_id: @book.id }
    end

    assert_redirected_to book_path(@book)
    assert_equal "貸出に失敗しました。", flash[:danger]
  end
end
