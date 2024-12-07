class ButtonTrackingWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'tracking',
                  lock: :until_and_while_executing

  def perform_with_error_handling(order_id)
    order = Order.includes(:order_amount).find(order_id)
    ButtonTrackingService.new(order).perform
  end
end
