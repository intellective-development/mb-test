class Order::PayTransitionWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(order_id)
    Order.find(order_id).tap do |order|
      order.trigger!(:pay) if order.in_state?(:verifying) && !order.fraud?
    end
  end
end
