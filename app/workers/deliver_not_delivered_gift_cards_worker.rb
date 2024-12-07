class DeliverNotDeliveredGiftCardsWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal'

  def perform_with_error_handling
    gift_cards = Coupon.active
                       .at(Time.zone.now)
                       .sent(Time.zone.now)
                       .joins('inner join order_items on coupons.order_item_id = order_items.id inner join shipments on shipments.id = order_items.shipment_id inner join orders on orders.id = shipments.order_id')
                       .where("coupons.delivered = false and coupons.recipient_email is not null and orders.state != 'canceled'")

    gift_cards.each do |gift_card|
      segment_service = Segments::SegmentService.from(gift_card.storefront)
      segment_service.identify_gift_card_recipient(gift_card.recipient_email)
      Coupon::GiftCardReceivedEvent.perform_in(2.minutes, gift_card.id, { send_immediately: true })
    end
  end
end
