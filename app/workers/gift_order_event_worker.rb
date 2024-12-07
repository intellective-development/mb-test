class GiftOrderEventWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options \
    queue: 'sync_profile',
    retry: true,
    lock: :until_executing

  def perform_with_error_handling(order_id, event_name)
    order = Order.find order_id
    return unless order.gift_detail.present?
    return if order.gift_detail.event_sent?
    return if order.canceled?
    return if order.shipping_methods.map(&:shipping_type).uniq == ['pickup'] # ISP gift orders are just the wrapping

    shipment = order.segment_most_relevant_shipment

    to_deliver = case event_name.to_s
                 when 'order_paid'
                   shipment.shipped? || (shipment.scheduled_for.present? && shipment.scheduled_for > Date.today)
                 when 'shipment_confirmed'
                   shipment.on_demand? && (shipment.scheduled_for.blank? || shipment.scheduled_for == Date.today)
                 else
                   false
                 end

    deliver_event! order, to_deliver
  end

  def deliver_event!(order, condition_to_deliver)
    return unless condition_to_deliver
    return if order.canceled?

    Segments::SegmentService.from(order.storefront).identify_gift_order_recipient(order)
    SendGiftOrderReceivedWorker.perform_in(2.minutes, order.id)
    order.gift_detail.update({ event_sent: true })
  end
end
