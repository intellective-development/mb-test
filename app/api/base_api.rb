require 'grape_logging'

class BaseAPI < Grape::API
  include API::DefaultHeaders
  include SentryNotifiable

  DOC_AUTH_ONLY_HEADER = {
    headers: {
      'Authorization' => {
        description: 'OAuth access token',
        required: true
      }
    }
  }.freeze

  rescue_from ActiveRecord::RecordNotFound do |e|
    params = @env['api.request.input']
    Rails.logger.info("ActiveRecord::RecordNotFound: #{e.message.to_s.delete("\n")} with params: #{params.to_s.delete("\n")}")
    error!({ error: { message: '404 Not Found' } }.to_json, 404)
  end

  rescue_from Grape::Exceptions::InvalidMessageBody do |e|
    MetricsClient::Metric.emit('minibar_web.error.invalid_message_body', 1)
    params = @env['api.request.input']
    Rails.logger.info("Grape::Exceptions::InvalidMessageBody: #{e.message.to_s.delete("\n")} with params: #{params.to_s.delete("\n")}")
    error!({ error: { message: '400 Bad Request' } }.to_json, 400)
  end

  rescue_from Grape::Exceptions::MethodNotAllowed do |e|
    MetricsClient::Metric.emit('minibar_web.error.method_not_allowed', 1)
    Rails.logger.info("Grape::Exceptions::MethodNotAllowed: #{e.message}")
    error!({ error: { message: '405 Not Allowed' } }.to_json, 405)
  end

  grape_custom_logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new($stdout))
  grape_custom_logger.formatter.extend JsonFormatter

  use GrapeLogging::Middleware::RequestLogger,
      logger: grape_custom_logger,
      log_level: 'info',
      include: [GrapeLogging::Loggers::Response.new,
                GrapeLogging::Loggers::FilterParameters.new,
                GrapeLogging::Loggers::ClientEnv.new,
                GrapeLogging::Loggers::RequestHeaders.new]

  use ApiErrorHandler
end
