class Order::NotifyGiftCardOrderNeedsReview
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(order_id)
    Order.find(order_id).tap do |order|
      InternalNotificationService.notify_order_needs_gift_card_image_review(order) if order.shipments.find(&:needs_gift_card_image_review?).present?
    end
  end
end
