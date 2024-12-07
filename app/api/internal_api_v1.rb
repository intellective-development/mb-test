# frozen_string_literal: true

# ErrorFormatter
module ErrorFormatter
  def self.call(message, _backtrace, _options, _env, _original_exception)
    message = message[:error] if message.is_a?(Hash) && message[:error].present?
    message = { message: message } if message.is_a?(String)
    { error: message }.to_json
  end
end

require 'doorkeeper/grape/helpers'

# InternalAPIV1
class InternalAPIV1 < BaseAPIV1
  helpers Doorkeeper::Grape::Helpers
  error_formatter :json, ErrorFormatter

  format :json
  version 'v1', using: :path
  prefix 'api/internal'

  before do
    authenticate_internal_api unless env['PATH_INFO'].include?('/checkout')
  end

  helpers do
    def authenticate_internal_api
      error!('Unauthorized', 401) if request_encrypted_access_token.nil? || !access_token_verified?
    end

    def access_token_verified?
      Doorkeeper::AccessToken.exists?(token: request_decrypted_access_token)
    end

    def request_decrypted_access_token
      InternalApiAccessTokenDecryptor.decrypt(request_encrypted_access_token)
    rescue OpenSSL::Cipher::CipherError, ArgumentError => e
      Rails.logger.warn "Error '#{e.message}' was raised while decrypting '#{request_encrypted_access_token}' access token"

      error!('Unauthorized', 401)
    end

    def request_encrypted_access_token
      headers['X-Access-Token']
    end
  end

  mount InternalAPIV1::StorefrontsEndpoint
  mount InternalAPIV1::OrdersEndpoint
  mount InternalAPIV1::CheckoutEndpoint
end
