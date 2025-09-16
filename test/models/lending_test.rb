require "test_helper"

class LendingTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @book = books(:one)
    @lending = lendings(:not_returned)
  end

  test "should lend book to user" do
    assert_difference "Lending.count", 1 do
      lending = Lending.lend_to(@user, @book)
      assert_equal @user, lending.user
      assert_equal @book, lending.book
      assert lending.persisted?
    end
  end

  test "should not allow lending when out of stock" do
    @book.update!(stock_count: 0)
    assert_raises Lending::OutOfStockError do
      Lending.lend_to(@user, @book)
    end
  end

  test "should allow user to return book" do
    assert_equal 1, @book.reload.stock_count
    @lending.return!
    assert_not_nil @lending.reload.returned_at
    assert_equal 2, @book.reload.stock_count
  end
end
