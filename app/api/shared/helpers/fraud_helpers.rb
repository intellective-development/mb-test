module Shared::Helpers::FraudHelpers
  def verify_no_robot
    RobotVerificationService.verify(fraud_options[:request])
  end

  def verify_no_login_fraud(access_token, session_id = nil)
    user, session, request = fraud_options(access_token, session_id).values_at(:user, :session, :request)
    if SessionVerificationService.delay_to_secure_account_overdue?(user)
      error!('Account access denied. Please reset your password.', 401)
    elsif SessionVerificationService.account_take_over?(user, session, request)
      error!('Account access denied. Please check email for instructions', 403)
    end
  end

  def notify_user_created(access_token, session_id = nil)
    user, session, request = fraud_options(access_token, session_id).values_at(:user, :session, :request)
    Fraud::CreateAccountEvent.new(user, session, request).call_async
  end

  def notify_user_logout(access_token, session_id = nil)
    user, session, request = fraud_options(access_token, session_id).values_at(:user, :session, :request)
    Fraud::LogoutEvent.new(user, session, request).call_async
  end

  def fraud_options(access_token = nil, session_id = nil)
    @access_token = access_token || @access_token
    @access_token ||= Doorkeeper::AccessToken.by_token(params[:token]) if params[:token]
    @fraud_options_user ||= RegisteredAccount.find_by(id: @access_token&.resource_owner_id)&.user if @access_token
    # try first to get the session_id from the scopes
    @fraud_options_session ||= Struct.new(:id).new(session_id) if session_id
    @fraud_options_session ||= Struct.new(:id).new(@access_token&.token) if @access_token
    @fraud_options_request ||= request
    {
      user: @fraud_options_user,
      session: @fraud_options_session,
      request: @fraud_options_request
    }
  end
end
