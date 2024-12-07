class Order::ConfirmDigitalShipmentsWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(order_id)
    order = Order.find(order_id)
    order.shipments.digital.select(&:can_autoconfirm?).reject(&:confirmed?).each(&:confirm!)
  end
end
