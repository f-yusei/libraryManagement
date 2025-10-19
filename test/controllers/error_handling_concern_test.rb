# frozen_string_literal: true

require "test_helper"
require "stringio"

class ErrorHandlingTestController < ApplicationController
  allow_unauthenticated_access only: %i[validation rate_limit record_missing parameter_missing]
  layout false

  def validation
    raise Exceptions::ValidationError
  end

  def rate_limit
    raise Exceptions::RateLimitExceededError
  end

  def record_missing
    raise ActiveRecord::RecordNotFound.new("Record not found")
  end

  def parameter_missing
    raise ActionController::ParameterMissing.new(:isbn)
  end
end

class ErrorHandlingConcernTest < ActionDispatch::IntegrationTest
  def draw_routes(routes)
    routes.draw do
      get "/signup", to: "users#new"
      resources :users
      resource :session
      resources :books do
        collection do
          get :search_isbn
          post :create_from_isbn
        end
      end
      resources :lendings, only: %i[create destroy index]
      resources :passwords, param: :token
      root "books#index"

      get "/error_handling/validation" => "error_handling_test#validation"
      get "/error_handling/rate" => "error_handling_test#rate_limit"
      get "/error_handling/missing" => "error_handling_test#record_missing"
      get "/error_handling/parameter_missing" => "error_handling_test#parameter_missing"
    end
  end

  test "renders html response for validation errors" do
    string_io = StringIO.new
    original_logger = Rails.logger
    Rails.logger = ActiveSupport::BroadcastLogger.new(ActiveSupport::Logger.new(string_io))

    with_routing do |routes|
      draw_routes(routes)

      get "/error_handling/validation"

      assert_response :unprocessable_entity
      assert_includes @response.body, "入力内容に誤りがあります。"
      assert_includes @response.body, "コード:"
    end

    assert_includes string_io.string, "code=validation_error"
  ensure
    Rails.logger = original_logger
  end

  test "renders json response for rate limit errors" do
    with_routing do |routes|
      draw_routes(routes)

      get "/error_handling/rate", as: :json

      assert_response :too_many_requests
      body = JSON.parse(@response.body)
      assert_equal "リクエストが多すぎます。", body["error"]
      assert_equal "rate_limit_exceeded", body["code"]
      assert_equal 429, body["status"]
    end
  end

  test "wraps ActiveRecord::RecordNotFound into custom error" do
    with_routing do |routes|
      draw_routes(routes)

      get "/error_handling/missing"

      assert_response :not_found
      assert_includes @response.body, "指定されたリソースが見つかりません。"
    end
  end

  test "renders turbo stream response that updates flash container" do
    with_routing do |routes|
      draw_routes(routes)

      get "/error_handling/validation", as: :turbo_stream

      assert_response :unprocessable_entity
      assert_includes @response.body, "turbo-stream"
      assert_includes @response.body, "target=\"flash_messages\""
    end
  end

  test "parameter missing is converted to bad request" do
    with_routing do |routes|
      draw_routes(routes)

      get "/error_handling/parameter_missing", as: :json

      assert_response :bad_request
      body = JSON.parse(@response.body)
      assert_equal "必要なパラメータが不足しています: isbn", body["error"]
      assert_equal "parameter_missing", body["code"]
      assert_equal 400, body["status"]
    end
  end
end
