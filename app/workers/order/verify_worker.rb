class Order::VerifyWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(order_id)
    MetricsClient::Metric.emit('workers.execution.verify_worker', 1)
    Rails.logger.info "minibar_web.workers.execution.verify_worker started for order #{order_id}"

    Order.find(order_id).tap do |order|
      OrderVerificationService.verify(order) if order.in_state?(:verifying)
    end
    nil
  end
end
