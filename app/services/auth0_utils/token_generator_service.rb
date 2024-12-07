# frozen_string_literal: true

module Auth0Utils
  class TokenGeneratorService < BaseService
    API_PATH = 'oauth/token'

    attr_reader :client, :storefront

    def initialize(storefront)
      @client = Auth0Client.new(storefront, true).call
      @storefront = storefront
    end

    def call
      access_token
    end

    private

    def access_token
      JSON.parse(request.body)['access_token']
    end

    def request
      client.public_send(:post, API_PATH, params)
    end

    def params
      {
        grant_type: 'client_credentials',
        client_id: storefront.auth0_api_client_id,
        client_secret: storefront.auth0_api_client_secret,
        audience: "#{client.url_prefix}api/v2/"
      }
    end
  end
end
