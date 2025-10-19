# frozen_string_literal: true

require "test_helper"

class ExceptionsTest < ActiveSupport::TestCase
  test "validation error default attributes" do
    error = Exceptions::ValidationError.new

    assert_equal "入力内容に誤りがあります。", error.message
    assert_equal "validation_error", error.code
    assert_equal 422, error.status
  end

  test "custom message overrides default" do
    error = Exceptions::ValidationError.new("別のメッセージ", code: "custom")

    assert_equal "別のメッセージ", error.message
    assert_equal "custom", error.code
  end

  test "rate limit error exposes integer status" do
    error = Exceptions::RateLimitExceededError.new

    assert_equal 429, error.status
  end

  test "bad request error defaults" do
    error = Exceptions::BadRequestError.new

    assert_equal "bad_request", error.code
    assert_equal 400, error.status
  end

  test "external service record not found defaults" do
    error = Exceptions::ExternalServiceRecordNotFoundError.new

    assert_equal "外部サービスのリソースが見つかりません。", error.message
    assert_equal "external_service_record_not_found", error.code
    assert_equal 404, error.status
  end
end
