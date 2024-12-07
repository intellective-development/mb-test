class Coupon::GiftCardPurchasedEvent
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_and_while_executing

  def perform_with_error_handling(order_item_id)
    gift_card_item = OrderItem.find order_item_id
    segment_service = Segments::SegmentService.from(gift_card_item.order.storefront)
    segment_service.gift_card_purchased(gift_card_item)
  end
end
