class Order::CancelShipmentsWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executed

  def perform_with_error_handling(order_id)
    Order.find(order_id).tap do |order|
      order.shipments.not_in_state(:pending, :canceled).filter { |s| s.can_transition_to?(:canceled) }.each(&:cancel!)
    end
  end
end
