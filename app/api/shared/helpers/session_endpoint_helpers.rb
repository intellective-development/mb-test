module Shared::Helpers::SessionEndpointHelpers
  extend Grape::API::Helpers

  def anonymous?
    params[:password].nil? && params[:password_confirmation].nil?
  end

  def available_or_current_email(email)
    accounts_with_email =  RegisteredAccount.where(email: email.downcase, storefront: storefront) # should only be at most 1 of these, treat as array just in case

    # check that either no users have the email, or that at least one user who does is the current user
    accounts_with_email.none? || accounts_with_email.any? { |a| a.user_id == @user.id }
  end

  def cancelled_guest_accounts?(email)
    guest_accounts_with_email = RegisteredAccount.guests
                                                 .where(contact_email: email&.downcase)

    # check if there is any cancelled guest account using that email.
    guest_accounts_with_email.present? && guest_accounts_with_email.any? { |a| a.state == 'canceled' }
  end

  def should_reauthenticate?
    # In the case where a user tries to change either their email address or
    # account password, we require them to re-authenticate with the existing
    # password.
    params[:existing_password].present? || (params[:email].present? && params[:email] != @user.email) || (params[:password].present? && !@user.account.valid_password?(params[:password]))
  end

  def validate_application!
    application = doorkeeper_application
    error!('invalid recaptcha', 400) if storefront.default_storefront? && application.requires_recaptcha? && !verify_no_robot
  end

  def set_temporary_password
    @temp_password = Time.zone.now.to_s
    params[:password] = @temp_password
    params[:password_confirmation] = @temp_password
  end
end
