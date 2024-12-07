class ConsumerAPIV2::AuthenticationEndpoint < BaseAPIV2
  helpers Shared::Helpers::AuthHelpers
  helpers Shared::Helpers::FraudHelpers

  before do
    validate_device_udid!
  end
  namespace :auth do
    desc 'Grants an access token, either with or without a resouce owner'
    params do
      use :client_params
      use :user_credentials
    end
    post :token do
      application = find_doorkeeper_application_from_client_credentials
      valid_recaptcha = verify_no_robot
      error!('invalid recaptcha') if application.requires_recaptcha? && !valid_recaptcha

      session_id = params[:session_id]

      access_token = if user_credentials_present?
                       Doorkeeper::AccessToken.find_or_create_for(
                         application: application,
                         resource_owner: find_user_account.id,
                         scopes: Doorkeeper::OAuth::Scopes.from_array([]),
                         expires_in: Doorkeeper.configuration.access_token_expires_in,
                         use_refresh_token: Doorkeeper.configuration.refresh_token_enabled?
                       )
                     else
                       Doorkeeper::AccessToken.find_or_create_for(
                         application: application,
                         resource_owner: nil,
                         scopes: Doorkeeper::OAuth::Scopes.from_array([]),
                         expires_in: Doorkeeper.configuration.access_token_expires_in,
                         use_refresh_token: Doorkeeper.configuration.refresh_token_enabled?
                       )
                     end

      jwt_expire_time = Time.now.to_i + Doorkeeper.configuration.access_token_expires_in.to_i
      verify_no_login_fraud(access_token, session_id)
      jwt_token = JwtTokenService.encode({ email: params[:email], external_id: access_token.resource_owner_id, iat: Time.now.to_i, exp: jwt_expire_time })

      status 200
      present access_token, with: ConsumerAPIV2::Entities::AccessToken, jwt_token: jwt_token
    end

    # Use refresh token to grant new tokens, if the paassed in token is valid
    desc 'Grants a new token, based on passed in refresh token'
    params do
      use :client_params
      use :refresh_token_params
    end
    post :refresh do
      # Get the application
      application = find_doorkeeper_application_from_client_credentials
      # Find the token for this given refresh token
      token = find_token_for_refresh_token(params[:client_id], params[:refresh_token])
      # Create and return a new token (even if a valid one still exists)
      access_token = Doorkeeper::AccessToken.create(
        application: token.application,
        resource_owner_id: token.resource_owner_id,
        scopes: token.scopes,
        use_refresh_token: Doorkeeper.configuration.refresh_token_enabled?,
        expires_in: Doorkeeper.configuration.access_token_expires_in
      )
      status 201
      present access_token, with: ConsumerAPIV2::Entities::AccessToken
    end

    # Revoke a given token
    desc 'Revokes the passed in token'
    params do
      use :revoke_token_params
    end
    post :revoke do
      token = find_token_to_revoke(params[:token])
      notify_user_logout(token, params[:session_id])
      if token
        account = RegisteredAccount.find_by(id: token.resource_owner_id)
        Doorkeeper::AccessToken.revoke_all_for(token.application_id, account) if account
      end
      # We return success independently if the token was found and revoked
      status 200
      {}
    end

    desc 'Creates a new user and returns an access token with resource owner context'
    params do
      use :client_params
      use :user_registration
    end
    post :create do
      application = find_doorkeeper_application_from_client_credentials
      valid_recaptcha = verify_no_robot
      error!('invalid recaptcha') if application.requires_recaptcha? && !valid_recaptcha

      # We want to validate the doorkeeper application before we attempt to
      # create a user - else we end up with a user, but are unable to issue an
      # access token.
      application = find_doorkeeper_application_from_client_credentials

      user, created = create_user(temp_password: false, application: application)
      session_id = params[:session_id]

      access_token = Doorkeeper::AccessToken.find_or_create_for(
        application: application,
        resource_owner: user.account_id,
        scopes: Doorkeeper::OAuth::Scopes.from_array([]),
        expires_in: Doorkeeper.configuration.access_token_expires_in,
        use_refresh_token: Doorkeeper.configuration.refresh_token_enabled?
      )

      if created
        notify_user_created(access_token, session_id)
      else
        verify_no_login_fraud(access_token, session_id)
      end

      status 201
      present access_token, with: ConsumerAPIV2::Entities::AccessToken
    end
  end
end
