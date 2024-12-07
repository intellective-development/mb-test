class CreateOrderAmountWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'high_priority', lock: :until_executing

  def perform_with_error_handling(order_id)
    Order.includes(:coupon, shipments: %i[order_items applied_deals]).find(order_id).tap do |order|
      break if order.order_amount

      order_amount = Order::Amounts.new(order)
      _coupon_amount = order_amount.coupon_amount # Pre-loading coupon amount
      order_amount_attrs = order_amount.to_attributes
      order.create_order_amount! order_amount_attrs
    end
  end
end
