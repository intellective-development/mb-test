class Coupon::GiftCardReceivedEvent
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_and_while_executing

  def perform_with_error_handling(gift_card_id, options = {})
    gift_card = Coupon.find gift_card_id
    segment_service = Segments::SegmentService.from(gift_card.storefront)
    segment_service.gift_card_received(gift_card, options)
    gift_card.deliver!

    DeliverDigitalShipmentWorker.perform_async(gift_card.order_item.shipment_id)
  end
end
