# frozen_string_literal: true

class AdminAPIV1
  # AdminAPIV1::RegisteredAccountsEndpoint
  class RegisteredAccountsEndpoint < BaseAPIV1
    format :json

    resource :registered_accounts do
      helpers AuthenticateWithToken
      before { authenticate_with_token!(ENV['BAR_OS_AUTH_TOKEN']) }

      desc 'Creates a new registered account'
      params do
        requires :uid, type: String, desc: 'Unique identifier'
        requires :provider, type: String, desc: 'Provider'
        requires :storefront_account_id, type: String, desc: 'Storefront Account ID'
        requires :email, type: String, desc: 'Customer Email'
        requires :storefront_id, type: Integer, desc: 'Storefront ID'
        optional :first_name, type: String, desc: 'Customer first name'
        optional :last_name, type: String, desc: 'Customer last name'
      end

      post do
        result = RegisteredAccounts::Create.call(params: params)

        error!({ name: 'RegisteredAccountCreationError', message: result.error }, 422) unless result.success?

        status :created
        present result.registered_account, with: AdminAPIV1::Entities::RegisteredAccount
      end
    end
  end
end
