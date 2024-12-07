class OAuthDefaultsController < ApplicationController
  protect_from_forgery

  # skip_before_action :check_for_lockup, raise: false

  def create
    user = User.find_by(access_token: params[:access_token])
    application = Doorkeeper::Application.find_by(uid: params[:client_id])
    resource = begin
      case params['type']
      when 'address'
        user.shipping_addresses.find_by(id: params[:resource_id])
      when 'payment_profile'
        user.payment_profiles.find_by(id: params[:resource_id])
      end
    rescue StandardError
      nil
    end

    if user && application && resource
      resource_copy = resource.dup
      resource_copy.update(doorkeeper_application: application,
                           default: true)

      render json: { resource_id: resource_copy.id }, status: :ok
    else
      render json: { error: true }, status: :internal_server_error
    end
  end
end
