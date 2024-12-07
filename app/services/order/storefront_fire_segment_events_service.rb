class Order::StorefrontFireSegmentEventsService
  def self.call(order:)
    if order.gift?
      Order::CreateVideoGiftMessageWorker.perform_async(order.id) and return if order.video_gift_order?

      GiftOrderEventWorker.perform_async(order.id, :order_paid)
      Order::SendGiftOrderCreatedEventWorker.perform_async(order.id)
    else
      return if order.digital?

      Order::SendOrderCreatedEventWorker.perform_async(order.id) unless order.all_shipments_pre_sale_or_back_order?
    end
  end
end
