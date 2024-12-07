class ConsumerAPIV2::ClientEndpoint < BaseAPIV2
  desc 'Retrieve provisioning information for API clients', ConsumerAPIV2::DOC_AUTH_HEADER
  params do
    optional :order_number, type: Integer
    optional :legacy_rb_paypal_supported, type: Boolean
  end
  get :client do
    encryption_key = ENV['BRAINTREE_CSE_KEY']

    @order = Order.find_by(number: @params[:order_number])
    @business = @order&.storefront&.business

    unless Feature[:skip_different_account_for_paypal].enabled?
      if !Business.default_business?(@business&.id) && params[:legacy_rb_paypal_supported].present? && @order&.legacy_rb_paypal_supported? # rubocop:disable Style/SoleNestedConditional
        error!('Credentials should be set up for a RB Paypal supported order.', 400) unless @business.braintree_credentials?

        gateway = PaymentGateway::Configuration.new(business: @business, payment_type: PaymentProfile::PAYPAL).gateway
        encryption_key = @business.braintree_cse_key
        client_token = gateway.client_token.generate
      end
    end

    client_token ||= Braintree::ClientToken.generate
    present :encryption_key, encryption_key
    present :client_token, client_token
  end
end
