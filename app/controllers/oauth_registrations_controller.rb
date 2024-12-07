class OAuthRegistrationsController < Devise::RegistrationsController
  layout 'oauth'

  # skip_before_action :check_for_lockup, raise: false

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) do |user_params|
      user_params.permit(:name, :email, :password, :password_confirmation, :first_name, :last_name)
    end
  end
end
