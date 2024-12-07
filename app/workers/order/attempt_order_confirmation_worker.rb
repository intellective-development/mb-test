class Order::AttemptOrderConfirmationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_and_while_executing

  def perform_with_error_handling(order_id)
    Order.includes(:shipments).find(order_id).tap do |order|
      order.confirm! if order.shipments.not_in_state(:confirmed, :delivered, :en_route).none?
    end
  end
end
