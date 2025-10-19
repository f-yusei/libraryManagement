# frozen_string_literal: true

require "test_helper"

class BaseServiceTest < ActiveSupport::TestCase
  class SampleService < BaseService
    def initialize(result)
      @result = result
    end

    def call
      @result
    end
  end

  test ".call delegates to #call on new instance" do
    assert_equal :ok, SampleService.call(:ok)
  end

  test "base service raises when #call not implemented" do
    assert_raises(NotImplementedError) { BaseService.new.call }
  end
end
