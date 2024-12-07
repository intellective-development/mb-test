# frozen_string_literal: true

# CheckoutAPIV1
class CheckoutAPIV1 < BaseAPIV1
  format :json
  version 'v1', using: :path
  prefix 'api/checkout'

  before do
    authenticate!
  end

  helpers do
    def authenticate!
      error!('Unauthorized', 401) unless auth_checks_passed?
    end

    def auth_checks_passed?
      params[:secret].present? && params[:user_id].present? && params[:storefront_id].present? && secret_valid?
    end

    def secret_valid?
      return false if user.nil?
      return false if storefront.nil?

      Checkout::Express::SecretHasher.new(user: user, storefront: storefront).secret_valid?(params[:secret])
    end

    def user
      @user ||= User.find_by(id: params[:user_id])
    end

    def storefront
      @storefront ||= Storefront.find_by(id: params[:storefront_id])
    end
  end

  mount CheckoutAPIV1::Express::OrdersEndpoint
end
