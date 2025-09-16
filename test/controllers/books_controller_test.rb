require "test_helper"

class BooksControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url
    assert_template "books/index"
    assert_response :success
  end
end
