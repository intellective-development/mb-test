class Order::UpdateGiftCardUsageWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(order_id)
    order = Order.find(order_id)
    segment_service = Segments::SegmentService.from(order.storefront)

    coupons = [order.coupon] + order.coupons
    coupons = coupons.compact.select(&:gift_card?)
    coupons.map(&:recipient_email).uniq.each do |recipient_email|
      segment_service.identify_gift_card_recipient(recipient_email)
    end
  end
end
