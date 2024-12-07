class Order::ApproveCustomGiftCardImagesWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(order_id)
    Order.find(order_id).tap do |order|
      order.shipments.digital.each(&:approve_custom_gift_card_images!)
    end
  end
end
