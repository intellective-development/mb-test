module Shared::Helpers::Auth0TokenHelpers
  extend Grape::API::Helpers

  def user_data_from_token(token, storefront)
    decoded_token = Auth0Utils::TokenDecoderService.call(token, storefront)
    user_data = Auth0Utils::UserDataFetcherService.call(decoded_token)

    error!('Invalid Token.', 401) if user_data.nil? || user_data[:uid].nil?

    user_data
  rescue StandardError => e
    error!({ name: 'Invalid Token', message: e.message }, 401)
  end
end
