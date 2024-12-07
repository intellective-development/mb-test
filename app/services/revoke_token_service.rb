# This class serves as a home for tasks associated with revoking authentication tokens.
# This includes:
#
# * Revoking any active OAuth Tokens for an account
#
class RevokeTokenService
  attr_reader :account

  def initialize(account)
    @account = account
  end

  def revoke_tokens
    return false unless account

    # We could also use the class method below if we wanted to revoke all keys
    # on a per-application basis.
    # Doorkeeper::AccessToken.revoke_all_for(application_id, resource_owner)
    Doorkeeper::AccessToken
      .where(revoked_at: nil, resource_owner_id: account.id)
      .find_each(&:revoke)
  end
end
