# frozen_string_literal: true

# rubocop:disable Lint/MissingSuper
module Auth0Utils
  module Passwordless
    # Auth0Utils::Passwordless::CodeGeneratorService
    #
    # Service that send the verification code to the auth0 api for passwordless login
    class CodeGeneratorService < BaseService
      API_PATH = 'passwordless/start'

      attr_reader :auth0_client, :storefront, :account, :login_type

      def initialize(storefront, account, login_type)
        @auth0_client = Auth0Client.new(storefront).call
        @storefront = storefront
        @account = account
        @login_type = login_type
      end

      def call
        generate_code
      end

      private

      def generate_code
        JSON.parse(request.body)
      rescue StandardError => e
        Rails.logger.error("Auth0 login code request: #{e.message}.\n Backtrace: #{e.backtrace.join("\n")}")
        raise e
      end

      def request
        auth0_client.public_send(:post, API_PATH, params)
      end

      def params
        {
          client_id: storefront.auth0_api_client_id,
          client_secret: storefront.auth0_api_client_secret,
          connection: login_type,
          email: account.contact_email || account.email,
          send: 'code'
        }.merge(login_type_params)
      end

      def login_type_params
        return {} unless login_type == 'sms'

        { phone_number: account.contact_phone_number || account.phone_number }
      end
    end
  end
end
# rubocop:enable Lint/MissingSuper
