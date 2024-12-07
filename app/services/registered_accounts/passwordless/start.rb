# frozen_string_literal: true

module RegisteredAccounts
  module Passwordless
    # RegisteredAccounts::Passwordless::Start
    #
    # Service that generate the code for passwordless authentication
    class Start
      attr_reader :storefront, :guest_account, :params

      def initialize(storefront, guest_account, params)
        @storefront = storefront
        @guest_account = guest_account
        @params = params
      end

      def call
        login_type = registered_account.present? ? start_with_registered_account : start_with_guest_account

        [login_type, registered_account&.login_providers]
      end

      private

      def start_with_registered_account
        registered_login_type = params[:login_type] || registered_account.phone_number.present? ? 'sms' : 'email'
        Auth0Utils::Passwordless::CodeGeneratorService.call(storefront, registered_account, registered_login_type)

        registered_login_type
      end

      def start_with_guest_account
        Auth0Utils::Passwordless::UserCreationService.call(storefront, guest_account, guest_login_type)
        Auth0Utils::Passwordless::CodeGeneratorService.call(storefront, guest_account, guest_login_type)

        guest_login_type
      end

      def registered_account
        return @registered_account if defined?(@registered_account)

        filter = guest_login_type == 'sms' ? { phone_number: phone_number } : { email: email }
        @registered_account = RegisteredAccount.find_by({ storefront: storefront }.merge(filter))
      end

      def email
        params[:email]
      end

      def phone_number
        params[:phone]
      end

      def guest_login_type
        params[:login_type] || phone_number.present? ? 'sms' : 'email'
      end
    end
  end
end
