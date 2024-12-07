class OrderCancellationNotifierWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'notifications_customer',
                  lock: :until_and_while_executing

  def perform_with_error_handling(order_id)
    CustomerNotifier.order_cancellation(order_id).deliver_now
  end
end
