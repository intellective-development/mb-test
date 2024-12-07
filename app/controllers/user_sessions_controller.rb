# Login failure: see config/initializers/warden.rb
class UserSessionsController < Devise::SessionsController
  layout 'minibar'
  respond_to :json

  def create
    RobotVerificationService.verify(request)
    super do |resource|
      if SessionVerificationService.delay_to_secure_account_overdue?(resource.user)
        sign_out
        flash[:alert] = 'Account access denied. Please reset your password.'
        respond_to do |format|
          format.json { render json: { error: flash[:alert] }, status: :unauthorized }
          format.html { redirect_to new_session_path(resource_name) }
        end
        return
      end
      if SessionVerificationService.account_take_over?(resource.user, session, request)
        sign_out
        # reset_session
        # clear_current_user # Clear current_user too otherwise server believes user is still signed in...
        flash[:alert] = 'Account access denied. Please check email for instructions.'
        respond_to do |format|
          format.json { render json: { error: flash[:alert] }, status: :unauthorized }
          format.html { redirect_to new_session_path(resource_name) }
        end
        return
      end
      if request.format == :json
        access_token = Doorkeeper::AccessToken.find_or_create_for(
          application: web_store_doorkeeper_app,
          resource_owner: resource.id,
          scopes: Doorkeeper::OAuth::Scopes.from_array([]),
          expires_in: Doorkeeper.configuration.access_token_expires_in,
          use_refresh_token: Doorkeeper.configuration.refresh_token_enabled?
        )
        response.headers['X-Minibar-Access-Token'] = access_token.token
      end
    end
  end

  def destroy
    Fraud::LogoutEvent.new(current_user, session, request).call_async
    # TODO: We should probably centralize the cookie cleanup code since we do
    # this also when assuming identity.
    cookies.delete(:address)
    cookies.delete(:cart_id)
    cookies.delete(:promo)
    cookies.delete(:sr_token)
    cookies.delete(:sid)
    super
  end

  def confirm_access
    authenticated_session = SessionVerificationService.confirm_by_token(params[:token], request)
    self.resource = authenticated_session&.user&.account
    flash[:alert] = 'Access confirmed. Please log in again.'
    redirect_to new_session_path(resource_name)
  end

  def deny_access
    authenticated_session = SessionVerificationService.deny_by_token(params[:token], request)
    self.resource = authenticated_session&.user&.account
    if resource
      token = reset_password_token(resource)
      render json: { reset_password_token: token }
    else
      redirect_to new_session_path(resource_name)
    end
  end

  private

  def reset_password_token(resource)
    token, enc = Devise.token_generator.generate(resource.class, :reset_password_token)
    resource.reset_password_token   = enc
    resource.reset_password_sent_at = Time.now.utc
    resource.save(validate: false)
    token
  end

  def user_params
    params.require(:user_session).permit(:password, :email, :remember_me, :storefront_id)
  end

  def web_store_doorkeeper_app
    Doorkeeper::Application.find_by(uid: ENV['WEB_STORE_CLIENT_ID'], secret: ENV['WEB_STORE_CLIENT_SECRET'])
  end
end
