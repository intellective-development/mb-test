# frozen_string_literal: true

module Auth0Utils
  class UserExistanceCheckerService < BaseService
    API_PATH = 'api/v2/users'

    attr_reader :client, :storefront, :email

    def initialize(storefront, email)
      @client = Auth0Client.new(storefront).call
      @storefront = storefront
      @email = email
    end

    def call
      fetch_user.present?
    end

    private

    def fetch_user
      JSON.parse(request.body)
    end

    def request
      client.public_send(:get, API_PATH, params, headers)
    end

    def params
      { q: %(email:"#{email}") }
    end

    def headers
      { 'authorization' => "Bearer #{generate_access_token}" }
    end

    def generate_access_token
      Auth0Utils::TokenGeneratorService.call(storefront)
    end
  end
end
