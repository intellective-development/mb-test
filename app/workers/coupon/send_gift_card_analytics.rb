class Coupon::SendGiftCardAnalytics
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_and_while_executing

  def perform_with_error_handling(shipment_id)
    shipment = Shipment.find(shipment_id)
    segment_service = Segments::SegmentService.from(shipment.order.storefront)

    shipment.order_items.gift_card.each do |gift_card_item|
      Coupon::GiftCardPurchasedEvent.perform_in(5.seconds, gift_card_item.id)
      Coupon.where(order_item: gift_card_item).each do |gift_card|
        segment_service.identify_gift_card_recipient(gift_card.recipient_email)
        # Coupon::GiftCardReceivedEvent.perform_in(2.minutes, gift_card.id)
      end
    end
  end
end
