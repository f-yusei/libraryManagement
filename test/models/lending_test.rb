require "test_helper"
class LendingTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @book = books(:one)
  end

  test "should lend book to user" do
    assert_difference "Lending.count", 1 do
      lending = Lending.lend_to(@user, @book)
      assert_equal @user, lending.user
      assert_equal @book, lending.book
      assert lending.persisted?
    end
  end

  test "should raise out of stock error" do
    @book.update!(stock_count: 0)
    assert_raises Lending::OutOfStockError do
      Lending.lend_to(@user, @book)
    end
  end
end
