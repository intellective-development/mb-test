class Coupon::GiftCardSummaryWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(order_item_ids)
    order_item = OrderItem.find order_item_ids.first
    sender = order_item.order.email
    gift_cards = Coupon.not_expired(Time.zone.now).where(order_item_id: order_item_ids)
    segment_service = Segments::SegmentService.from(order_item.order.storefront)
    segment_service.gift_card_summary(sender, gift_cards, order_item&.item_options&.file&.url)
  end
end
