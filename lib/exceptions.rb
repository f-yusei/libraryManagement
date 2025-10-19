# frozen_string_literal: true

module Exceptions
  class ApplicationError < StandardError
    DEFAULT_MESSAGE = "アプリケーションエラーが発生しました。"
    DEFAULT_CODE = "application_error"
    STATUS = 500

    attr_reader :code, :status

    def initialize(message = nil, code: nil, status: nil)
      super(message || self.class::DEFAULT_MESSAGE)
      @code = code || self.class::DEFAULT_CODE
      @status = status || self.class::STATUS
    end
  end

  class BadRequestError < ApplicationError
    DEFAULT_MESSAGE = "不正なリクエストです。"
    DEFAULT_CODE = "bad_request"
    STATUS = 400
  end

  class ValidationError < ApplicationError
    DEFAULT_MESSAGE = "入力内容に誤りがあります。"
    DEFAULT_CODE = "validation_error"
    STATUS = 422
  end

  class NotPermittedError < ApplicationError
    DEFAULT_MESSAGE = "操作が許可されていません。"
    DEFAULT_CODE = "not_permitted"
    STATUS = 403
  end

  class RecordNotFoundError < ApplicationError
    DEFAULT_MESSAGE = "指定されたリソースが見つかりません。"
    DEFAULT_CODE = "record_not_found"
    STATUS = 404
  end

  class RateLimitExceededError < ApplicationError
    DEFAULT_MESSAGE = "リクエストが多すぎます。"
    DEFAULT_CODE = "rate_limit_exceeded"
    STATUS = 429
  end

  class ExternalServiceError < ApplicationError
    DEFAULT_MESSAGE = "外部サービスでエラーが発生しました。"
    DEFAULT_CODE = "external_service_error"
    STATUS = 503
  end

  class ExternalServiceRecordNotFoundError < ApplicationError
    DEFAULT_MESSAGE = "外部サービスのリソースが見つかりません。"
    DEFAULT_CODE = "external_service_record_not_found"
    STATUS = 404
  end
end
