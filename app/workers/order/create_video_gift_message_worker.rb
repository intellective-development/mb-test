class Order::CreateVideoGiftMessageWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(order_id)
    Order::CreateVideoGiftMessageService.new(order_id: order_id).call
  end
end
