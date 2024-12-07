class Order::CreateYotpoOrderWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(order_id)
    Order.find(order_id).tap do |order|
      success = YotpoService.new.create_order(order)
      raise 'CreateYotpoOrderWorker error' unless success
    end
  end
end
