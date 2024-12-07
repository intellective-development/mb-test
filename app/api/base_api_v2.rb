class BaseAPIV2 < BaseAPI
  rescue_from Auth0Error do |exception|
    error!(exception.message, 400)
  end

  rescue_from Faraday::ClientError do |exception|
    message = exception&.response&.[](:body) || exception.message
    status = exception&.response&.[](:status) || 400
    error!(message, status)
  end
end
