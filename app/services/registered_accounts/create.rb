# frozen_string_literal: true

module RegisteredAccounts
  # RegisteredAccounts::Create
  class Create < BaseService
    attr_reader :registered_account, :error

    KEYS = %i[email uid provider storefront_id storefront_account_id first_name last_name].freeze

    def initialize(params:)
      @params = params.dup
    end

    def call
      @registered_account = find_or_initialize_registered_account

      ActiveRecord::Base.transaction do
        handle_provider
        registered_account.update!(prepared_params)
        registered_account.user.save!
      rescue StandardError => e
        @error = e.message

        raise ActiveRecord::Rollback
      end

      self
    end

    def success?
      @error.nil?
    end

    private

    attr_reader :params

    def find_or_initialize_registered_account
      ::RegisteredAccount.find_or_initialize_by(
        storefront_id: params[:storefront_id],
        uid: params[:uid],
        email: params[:email],
        provider: "liquid:#{params[:provider]}"
      )
    end

    def handle_provider
      return unless 'LoginProvider'.safe_constantize
      return find_or_create_provider if registered_account.persisted?

      registered_account.login_providers << ::LoginProvider.new(key: "liquid:#{params[:provider]}")
    end

    def find_or_create_provider
      ::LoginProvider.find_or_create_by!(
        registered_account: registered_account,
        key: "liquid:#{params[:provider]}"
      )
    end

    def prepared_params
      temp_password = SecureRandom.uuid
      params.delete(:email) if registered_account.persisted?

      params.slice(*KEYS).merge(
        password: temp_password,
        password_confirmation: temp_password,
        provider: "liquid:#{params[:provider]}",
        first_name: normalize_name(params[:first_name]),
        last_name: normalize_name(params[:last_name])
      )
    end

    def normalize_name(name)
      name.gsub(/[^0-9a-z'\- ]/i, '').gsub(/'+$/, '')
    end
  end
end
