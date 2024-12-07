module SentryNotifiable
  extend ActiveSupport::Concern

  included do
    # include callbacks
  end

  def notify_sentry_and_log(exception, message = nil, attributes = {})
    message ||= exception.message

    Rails.logger.error(message)
    notify_sentry(exception, message, attributes)
  end

  def message_sentry_and_log(message, attributes = {})
    Rails.logger.error(message)

    Sentry.configure_scope do |scope|
      scope.set_context('attributes', attributes)
      Sentry.capture_message(message)
    end
  rescue StandardError => e
    Rails.logger.error("Unable to log to sentry: #{e.message}")
  end

  private

  def notify_sentry(exception, message, attributes = {})
    attributes = attributes.to_h.transform_keys(&:to_sym) unless attributes.empty?
    attributes[current_user: current_user] if defined?(current_user)
    attributes[error_message: message] = (message.presence || exception.message)

    Sentry.configure_scope do |scope|
      scope.set_context('attributes', attributes)
      Sentry.capture_exception(exception)
    end
  rescue StandardError => e
    Rails.logger.error("Unable to log to sentry: #{e.message}")
  end
end
