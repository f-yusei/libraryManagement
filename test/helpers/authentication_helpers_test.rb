require "test_helper"

class AuthenticationHelpersTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two)
  end

  test "sign_in_as helper method works correctly" do
    # 既存のセッションをクリア
    Current.session = nil

    # sign_in_asを実行前のセッション数を記録
    initial_session_count = Session.count

    # sign_in_asを実行
    sign_in_as(@user)

    # セッションレコードが作成されていることを確認
    assert_equal initial_session_count + 1, Session.count, "New session should be created"
    latest_session = Session.last
    assert_equal @user.id, latest_session.user_id, "Session should belong to the correct user"

    # 認証が必要なページにアクセスできることを確認
    get books_path
    assert_response :success, "Should be able to access authenticated pages"
  end

  test "sign_in_as with follow option works correctly" do
    # 既存のセッションをクリア
    Current.session = nil

    # sign_in_asを実行前のセッション数を記録
    initial_session_count = Session.count

    # sign_in_asをfollow: trueで実行
    sign_in_as(@user, follow: true)

    # セッションレコードが作成されていることを確認
    assert_equal initial_session_count + 1, Session.count, "New session should be created"
    latest_session = Session.last
    assert_equal @user.id, latest_session.user_id, "Session should belong to the correct user"

    # リダイレクト後のレスポンスが成功していることを確認（follow: trueの効果）
    assert_response :success, "Should follow redirect and get success response"
  end

  test "sign_in_as with wrong password redirects with alert" do
    # 存在しないパスワードでサインインを試行
    post session_path, params: { email_address: @user.email_address, password: "wrong_password" }

    # ログインページにリダイレクトされることを確認
    assert_redirected_to new_session_path
    follow_redirect!

    # アラートメッセージが表示されることを確認
    assert_match "Try another email address or password", flash[:alert]
  end

  test "sign_out helper method works correctly" do
    # まずサインイン
    sign_in_as(@user)

    # サインインできていることを確認
    get books_path
    assert_response :success

    # サインアウト
    sign_out

    # セッションがクリアされていることを確認（新しいリクエストで）
    # 新しいリクエストを送信して認証状態をチェック
    post lendings_path, params: { book_id: books(:one).id }
    assert_redirected_to new_session_path, "Should redirect to login page after sign out"
  end
end
