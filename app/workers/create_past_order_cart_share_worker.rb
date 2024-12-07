class CreatePastOrderCartShareWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'default', lock: :until_executing

  def perform_with_error_handling(order_id)
    Order.find(order_id).tap do |order|
      CartShare.create_from_order(order, :past_order)
    end
  end
end
