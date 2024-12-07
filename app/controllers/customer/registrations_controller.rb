class Customer::RegistrationsController < Devise::RegistrationsController
  layout 'minibar'
  before_action :configure_permitted_parameters, if: :devise_controller?
  respond_to :json

  def create
    RobotVerificationService.verify(request)
    super do |resource|
      # we check persisted? and active_for_authentication? to match super's success case
      if resource.persisted? && resource.active_for_authentication?
        # HACK: Ensures that the user model is being saved, if it hasn't already been.
        # This should be taken care of by the autosave on the RegisteredAccount has_one User.
        resource.user.save if resource.user.new_record?
        Fraud::CreateAccountEvent.new(resource.user, session, request).call_async

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
  end

  protected

  def after_sign_up_path_for(_resource)
    if params[:return_to].present?
      params[:return_to]
    elsif params.dig(:registered_account, :return_to).present?
      params.dig(:registered_account, :return_to)
    elsif current_user.admin?
      '/admin'
    elsif current_user.supplier?
      'https://partners.minibardelivery.com/'
    else
      '/store'
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) do |user_params|
      user_params.permit(:name, :email, :contact_email, :password, :password_confirmation, :first_name, :last_name)
    end
  end

  def build_resource(hash = {})
    # Users who signed up via Minibar website should be registered in Minibar storefront
    super(hash).tap do |account|
      account.storefront_id = Storefront::MINIBAR_ID
    end
  end

  def web_store_doorkeeper_app
    Doorkeeper::Application.find_by(uid: ENV['WEB_STORE_CLIENT_ID'], secret: ENV['WEB_STORE_CLIENT_SECRET'])
  end
end
