class Coupon::DeliverGiftCardWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true, queue: 'internal'

  def perform_with_error_handling(gift_card_id, options = {})
    gift_card = Coupon.find gift_card_id
    order = gift_card.order_item.order
    return if order&.canceled?
    return if gift_card.expires_at <= Date.today
    return if gift_card.delivered && !options['resend']
    # we won't execute if the date was changed
    return if gift_card.send_date > Date.today && !options['resend']

    segment_service = Segments::SegmentService.from(order.storefront)
    segment_service.identify_gift_card_recipient(gift_card.recipient_email)
    Coupon::GiftCardReceivedEvent.perform_in(2.minutes, gift_card.id, { send_immediately: true })
  end
end
