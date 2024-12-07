class OrderFraudScoreWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: 5,
                  queue: 'internal',
                  lock: :until_executing

  def perform_with_error_handling(order_id)
    order = Order.find(order_id)
    order.create_fraud_score unless order.bulk_order?
  end
end
