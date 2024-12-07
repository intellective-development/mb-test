# frozen_string_literal: true

module Auth0Utils
  class UserCreationService < BaseService
    API_PATH = 'dbconnections/signup'

    attr_reader :client, :storefront, :email, :password, :account

    def initialize(storefront, email, password, account)
      @client = Auth0Client.new(storefront).call
      @storefront = storefront
      @email = email
      @password = password
      @account = account
    end

    def call
      validate_params
      create_user
    end

    private

    def validate_params
      raise Auth0Errors::AccountAlreadyExistsError if UserExistanceCheckerService.call(storefront, email)
      raise Auth0Errors::WeakPasswordError unless strong_password?
    end

    def strong_password?
      password.match?(/^(?=.*\d)(?=.*([a-z]|[A-Z]))([\x20-\x7E]){8,}$/)
    end

    def create_user
      JSON.parse(request.body)
    end

    def request
      client.public_send(:post, API_PATH, params)
    end

    def params
      {
        client_id: storefront.auth0_client_id,
        email: email,
        password: password,
        name: account.name,
        connection: storefront.auth0_db_connection,
        user_metadata: {
          storefront_id: storefront.id,
          storefront_pim_name: storefront.pim_name,
          signup_origin: 'checkout',
          given_name: account.first_name,
          family_name: account.last_name
        }
      }
    end
  end
end
