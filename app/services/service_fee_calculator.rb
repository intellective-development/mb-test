class ServiceFeeCalculator
  def initialize(order)
    @order = order
  end

  # This might become more complex in the future so I'm creating a service to calculate the service fee
  def fee_amount
    # No service fee for gift cards
    return 0.0 if @order.digital?

    # No service fee, if there is a coupon for free service fee
    return 0.0 if @order.all_coupons.any?(&:free_service_fee?)

    @order.storefront.business.service_fee.to_f
  end
end
