class OAuthAddressesController < ApplicationController
  protect_from_forgery

  # skip_before_action :check_for_lockup, raise: false

  def create
    user = User.find_by(access_token: params[:access_token])
    application = Doorkeeper::Application.find_by(uid: params[:client_id])

    if user && application
      address = AddressCreationService.new(user, application).create(params.permit![:address_params].to_h.merge(default: true, address_purpose: :shipping))
      if address
        render json: { resource_id: address.id }, status: :ok
      else
        render json: { error: true }, status: :internal_server_error
      end
    else
      render json: { error: true }, status: :internal_server_error
    end
  end
end
