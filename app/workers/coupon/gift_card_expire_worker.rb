class Coupon::GiftCardExpireWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(order_item_ids)
    gift_cards = Coupon.where(order_item_id: order_item_ids)
    gift_cards.each do |gift_card|
      gift_card.expire!
      segment_service = Segments::SegmentService.from(gift_card.storefront)
      segment_service.gift_card_expired(gift_card)
      segment_service.identify_gift_card_recipient(gift_card.recipient_email)
    end
  end
end
