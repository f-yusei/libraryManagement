# frozen_string_literal: true

module ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from Exceptions::ApplicationError, with: :render_application_error
    rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
    rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found
    rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
  end

  private

  def handle_record_invalid(exception)
    message = exception.record&.errors&.full_messages&.to_sentence
    render_application_error(Exceptions::ValidationError.new(message.presence), exception)
  end

  def handle_record_not_found(exception)
    render_application_error(Exceptions::RecordNotFoundError.new, exception)
  end

  def handle_parameter_missing(exception)
    message = "必要なパラメータが不足しています: #{exception.param}"
    error = Exceptions::BadRequestError.new(message, code: "parameter_missing")
    render_application_error(error, exception)
  end

  def render_application_error(error, original_exception = nil)
    log_application_error(error, original_exception)
    @error = error

    respond_to do |format|
      format.json { render json: { error: error.message, code: error.code, status: error.status }, status: error.status }
      format.turbo_stream do
        render "shared/errors/show", formats: :turbo_stream, status: error.status
      end
      format.html do
        render "shared/errors/show", status: error.status
      end
      format.any { head error.status }
    end
  end

  def log_application_error(error, original_exception)
    logger = Rails.logger
    return unless logger

    severity = error.status.to_i >= 500 ? :error : :warn
    payload = {
      code: error.code,
      message: error.message,
      status: error.status,
      method: request&.request_method,
      path: request&.fullpath,
      user_id: Current.session&.user&.id
    }.compact

    logger.send(severity, payload.map { |key, value| "#{key}=#{value}" }.join(" "))

    exception = original_exception || error
    if error.status.to_i >= 500 && exception&.backtrace&.any?
      logger.debug(exception.backtrace.join("\n"))
    end
  end
end
