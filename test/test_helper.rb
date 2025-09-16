ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

module AuthenticationHelpers
  # リダイレクトを追跡する場合は `follow: true` を指定する
  def sign_in_as(user, password: "password", follow: false)
    post session_path, params: { email_address: user.email_address, password: password }
    assert_response :redirect if respond_to?(:assert_response)

    if follow
      follow_redirect!
      assert_response :success
    end
  end



  def sign_out
    delete session_path(:current) rescue delete session_path
  end
end

class ActionDispatch::IntegrationTest
  include AuthenticationHelpers
end
