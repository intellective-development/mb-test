# This service handles any client authentication boilerplate for the website.
#
# Since tokens have a long expiry, we are storing in memcache to avoid excessive
# creation of new tokens.

class WebAuthenticationService
  def self.resource_owner_token(application_uid, registered_account)
    app = Doorkeeper::Application.find_by(uid: application_uid)
    Doorkeeper::AccessToken.find_or_create_for(
      application: app,
      resource_owner: registered_account.id,
      scopes: Doorkeeper::OAuth::Scopes.from_array([]),
      expires_in: Doorkeeper.configuration.access_token_expires_in,
      use_refresh_token: Doorkeeper.configuration.refresh_token_enabled?
    )
  rescue StandardError => e
    # We don't have a database yet!
    Rails.logger.error("Attempted to create resource_owner token when table does not yet exist. #{e.message}")
    nil
  end

  def self.client_credentials_token(application_uid)
    Rails.cache.fetch("web_authentication:client_credentials_token:#{application_uid}", expires_in: 24.hours) do
      app = Doorkeeper::Application.find_by(uid: application_uid)
      token = if app
                Doorkeeper::AccessToken.find_or_create_for(
                  application: app,
                  resource_owner: nil,
                  scopes: Doorkeeper::OAuth::Scopes.from_array([]),
                  expires_in: Doorkeeper.configuration.access_token_expires_in,
                  use_refresh_token: Doorkeeper.configuration.refresh_token_enabled?
                )
              end
      token
    end
  rescue StandardError => e
    # We don't have a database yet!
    Rails.logger.error("Attempted to create client_credentials token when table does not yet exist. #{e.message}")
    nil
  end
end
