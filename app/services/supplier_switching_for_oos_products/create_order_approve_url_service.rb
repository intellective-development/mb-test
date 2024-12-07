# frozen_string_literal: true

module SupplierSwitchingForOosProducts
  # SupplierSwitchingForOosProducts::CreateApproveUrlService
  class CreateOrderApproveUrlService < BaseService
    def initialize(order_id:)
      super

      @order = Order.find(order_id)
      @user = @order.user
      @storefront = @order.storefront
    end

    def call
      build_approve_url
    end

    private

    def build_approve_url
      URI::HTTPS.build(
        host: approve_url_host,
        path: '/api/checkout/v1/express/orders/approve',
        query: approve_url_params
      ).to_s
    end

    def approve_url_host
      URI.parse(ENV['BASE_URL']).host
    end

    def approve_url_params
      {
        user_id: @user.id,
        storefront_id: @storefront.id,
        order_number: @order.number,
        secret: Checkout::Express::SecretHasher.new(user: @user, storefront: @storefront).encode
      }.compact.map { |k, v| "#{k}=#{v}" }.join('&')
    end
  end
end
