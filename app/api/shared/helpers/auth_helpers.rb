# frozen_string_literal: true

module Shared::Helpers::AuthHelpers # rubocop:disable Metrics/ModuleLength
  extend Grape::API::Helpers

  include Shared::Helpers::Auth0TokenHelpers

  params :client_params do
    requires :client_id,     type: String, allow_blank: false
    requires :client_secret, type: String, allow_blank: false
    optional :session_id, type: String, allow_blank: false
  end

  params :user_credentials do
    optional :email,    type: String, allow_blank: false, regexp: CustomValidators::Emails.email_validator, coerce_with: ->(val) { String(val).downcase.squish }
    optional :password, type: String, allow_blank: false
    optional :session_id, type: String, allow_blank: false
    all_or_none_of :email, :password
  end

  params :refresh_token_params do
    requires :refresh_token, type: String, allow_blank: false
  end

  params :revoke_token_params do
    requires :token, type: String, allow_blank: false
    optional :session_id, type: String, allow_blank: false
  end

  params :user_registration do
    requires :email,                  type: String, regexp: CustomValidators::Emails.email_validator, coerce_with: ->(val) { String(val).downcase.squish }
    requires :first_name,             type: String, allow_blank: false, regexp: /\w{1,255}/
    requires :last_name,              type: String, allow_blank: false, regexp: /\w{1,255}/
    optional :contact_email,          type: String, regexp: CustomValidators::Emails.email_validator, coerce_with: ->(val) { String(val).downcase.squish }
    optional :password,               type: String, allow_blank: false, regexp: /.{6,255}/
    optional :password_confirmation,  type: String, allow_blank: false, regexp: /.{6,255}/
    all_or_none_of :password, :password_confirmation
  end

  params :liquid_tokens do
    optional :liquid_id_token,     type: String, allow_blank: false
    optional :liquid_access_token, type: String, allow_blank: false
    all_or_none_of :liquid_id_token, :liquid_access_token
  end

  def user_credentials_present?
    params[:email].present? && params[:password].present?
  end

  def find_doorkeeper_application_from_client_credentials
    return @find_doorkeeper_application_from_client_credentials if defined? @find_doorkeeper_application_from_client_credentials

    app = @find_doorkeeper_application_from_client_credentials = Rails.cache.fetch("doorkeeper_application:#{params[:client_id]}:#{params[:client_secret]}", expires_in: 5.minutes) do
      Doorkeeper::Application.find_by(uid: params[:client_id], secret: params[:client_secret])
    end
    error!('Invalid Client Credentials', 401) unless app
    app
  end

  def find_user_account
    account = RegisteredAccount.authenticate(params[:email], params[:password])
    error!('Invalid Email Address or Password', 404) unless account
    error!('Account Disabled', 403)                  if account&.canceled?
    SegmentIdentifyWorker.perform_async(account&.user&.id)
    account
  end

  # Return a new token if the given refrsh token and client id are valid
  def find_token_for_refresh_token(client_id, refresh_token)
    # Get token from the given refresh token
    token = Doorkeeper::AccessToken.by_refresh_token(refresh_token)

    # If token doesn't exist at all, client id doen't match or token has been revoked, this isn't valid
    error!('Invalid Client Credentials', 401) unless token && token.application.uid == client_id
    error!('Invalid Token', 401) if token.revoked?

    token
  end

  # Try to find a given token, be it an access or refresh token
  def find_token_to_revoke(token)
    # Try to find token first as an access token
    t = Doorkeeper::AccessToken.find_by(token: token)
    # Then by refresh token if still nil
    t ||= Doorkeeper::AccessToken.find_by(refresh_token: token)
  end

  def user_params
    @user_params ||= clean_params(params).permit(:email, :contact_email, :password_confirmation,
                                                 :password, :first_name, :last_name)
  end

  def create_user(temp_password: false, application: nil)
    error!('Password and Password Confirmation must match.', 400) if params[:password] != params[:password_confirmation]

    guest_account = RegisteredAccount.find_by(storefront_id: storefront.id, contact_email: params[:email].downcase)

    # only minibar, reservebar and get stocked support logged in users
    # other partners are all guest experiences
    error!('Email address belongs to an existing user.', 409) if storefront.operated_and_owned? && RegisteredAccount.email_exists?(storefront, params[:contact_email], params[:email])

    # this lock is based on the email for the user being created. if there is a contact email then use it
    # if not, use the email. this avoids locking the entire function regardless of the email
    user, created = User.with_advisory_lock("user_create_#{params[:email]}") do
      user_params[:storefront_id] = storefront.id
      user_attributes = build_user_attributes(client_details.client, application, anonymous: temp_password)

      user = if guest_account
               update_guest_user(guest_account, user_attributes)
             else
               User.create!(user_attributes)
             end

      [user, true]
    end
    [user, created]
  end

  def process_liquid_user
    user, created = User.with_advisory_lock('liquid_user_create') do
      user_params[:storefront_id] = storefront.id
      user_attributes = build_user_attributes(client_details.client, doorkeeper_token&.application)
      user = create_liquid_user(user_attributes)
      user ? [user, true] : [nil, false]
    end
    [user, created]
  end

  def create_liquid_user(user_attributes)
    liquid_access_token = params[:liquid_access_token]
    return unless liquid_access_token

    user_from_token = user_data_from_token(liquid_access_token, storefront)

    liquid_account = RegisteredAccount.find_by(
      uid: user_from_token[:uid], provider: user_from_token[:provider], storefront_id: storefront.id
    )

    if liquid_account
      begin
        LoginProvider.find_or_create_by!(registered_account: liquid_account, key: user_from_token[:provider])
      rescue e
        msg_data = "registered_account_id: #{liquid_account.id}, provider: #{user_from_token[:provider]}"
        Rails.logger.info("Login provider error: #{e.message}.\n Backtrace: #{e.backtrace.join("\n")}\n Data: #{msg_data}")
      end

      return liquid_account.user
    end

    if user_from_token[:email].blank? || RegisteredAccount.email_exists?(storefront, nil, user_from_token[:email])
      Rails.logger.error "Create liquid user error: Email cannot be blank (#{user_from_token})" if user_from_token[:email].blank?

      error!('Invalid User Token', 401)
    end

    user_attributes[:account_attributes] = user_from_token.merge(allow_no_password: true, storefront: storefront)
    user = RegisteredAccount.new.user
    user.account.login_providers << LoginProvider.new(key: user_from_token[:provider])
    user.update!(user_attributes)
    bar_os_user_create!(user)
    user
  end

  def update_guest_user(guest_account, user_attributes)
    user_attributes[:account_attributes] = user_attributes[:account_attributes].merge(email: user_params[:email], contact_email: nil)
    user = guest_account.user
    user.update!(user_attributes)
    user
  end

  def build_user_attributes(utm_source, application, anonymous: false)
    {
      account_attributes: user_params,
      utm_source: utm_source,
      utm_medium: 'api/v2',
      anonymous: anonymous,
      doorkeeper_application: doorkeeper_token&.application || application
    }
  end

  def create_guest_user
    temp_password = SecureRandom.uuid
    params[:password] = temp_password
    params[:password_confirmation] = temp_password
    params[:email] = "#{SecureRandom.uuid}@anonymo.us"
    params[:contact_email] = 'guest@account.com'
    params[:first_name] = 'Guest'
    params[:last_name] = 'Account'
    user, created = create_user(temp_password: temp_password)
    user
  end

  def liquid_user?
    @user&.account&.provider&.include? 'liquid:'
  end

  def bar_os_user_create!(user)
    return if ENV['KAFKA_KIT_ENABLED'].to_s != 'true' || !user.account_id

    ::BarOSAPI::Admin::V1::RegisteredAccounts.create(id: user.account_id, request: { timeout: 1 })
  rescue Faraday::Error # rubocop:disable Lint/SuppressedException
  end
end
