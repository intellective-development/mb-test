class OAuthPaymentMethodsController < ApplicationController
  protect_from_forgery

  # skip_before_action :check_for_lockup, raise: false

  def create
    user = User.find_by(access_token: params[:access_token])
    application = Doorkeeper::Application.find_by(uid: params[:client_id])

    if user && application
      address = AddressCreationService.new(user, application).create_billing_address(params[:name], params[:zip_code])

      payment_method = PaymentMethodCreationService.new(user, application).create({ payment_method_nonce: params[:payment_method_nonce] }, address)

      if payment_method
        payment_method.update(default: true, doorkeeper_application: application)
        render json: { resource_id: payment_method.id }, status: :ok
      else
        render json: { error: true }, status: :internal_server_error
      end
    else
      render json: { error: true }, status: :internal_server_error
    end
  end
end
