class ShopRunner::ShipmentWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'tracking',
                  lock: :until_and_while_executing

  def perform_with_error_handling(order_id)
    order = Order.find(order_id)
    ShopRunner::ShipmentFeedService.new(order).call
  end
end
