class Order::LateRefundWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(order_id)
    Order.find(order_id).tap do |order|
      if order.canceled?
        order.charges.each { |charge| charge.cancel! if charge.can_be_cancelled? }
        order.refund_order_charges!
      end
    end
  end
end
