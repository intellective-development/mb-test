# frozen_string_literal: true

module Auth0Utils
  class UserDataFetcherService < BaseService
    attr_reader :token

    def initialize(token)
      @token = token
    end

    def call
      parse_token_user_data
    end

    private

    def parse_token_user_data
      token_user_data = token[0] || {}
      provider, uid = token_user_data&.[]('sub')&.split('|')
      {
        uid: uid,
        provider: "liquid:#{provider}",
        email: token_user_data['email'],
        first_name: token_user_data['given_name'],
        last_name: token_user_data['family_name']
      }
    end
  end
end
