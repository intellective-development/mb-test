# frozen_string_literal: true

# rubocop:disable Lint/MissingSuper
module Auth0Utils
  module Passwordless
    # Auth0Utils::Passwordless::UserCreationService
    #
    # Service that create a new user on auth0 api for passwordless login
    class UserCreationService < BaseService
      API_PATH = 'api/v2/users'

      attr_reader :auth0_client, :storefront, :account, :login_type

      def initialize(storefront, account, login_type)
        @auth0_client = Auth0Client.new(storefront).call
        @storefront = storefront
        @account = account
        @login_type = login_type
      end

      def call
        create_user
      end

      private

      def create_user
        JSON.parse(request.body)
      rescue StandardError => e
        Rails.logger.error("Auth0 user creation error: #{e.message}.\n Backtrace: #{e.backtrace.join("\n")}")
        raise e
      end

      def headers
        { 'authorization' => "Bearer #{generate_access_token}" }
      end

      def generate_access_token
        Auth0Utils::TokenGeneratorService.call(storefront)
      end

      def request
        auth0_client.public_send(:post, API_PATH, params, headers)
      end

      def params
        {
          email: account.contact_email,
          given_name: account.name,
          connection: login_type
        }.merge(login_type_params)
      end

      def login_type_params
        {
          sms: -> { { phone_number: account.contact_phone_number, phone_verified: true } },
          email: -> { { email_verified: true } }
        }[login_type.to_sym].call
      end
    end
  end
end
# rubocop:enable Lint/MissingSuper
