class Order::MinibarFireSegmentEventsService
  def self.call(order:)
    if order.first_paid_order_of_user?
      Order::SendNewBuyerEventWorker.perform_async(order.id)
      Order::SendGuestOrderEventWorker.perform_async(order.id) if order.user.account.guest?
    else
      Order::SendOrderCreatedEventWorker.perform_async(order.id)
    end
    GiftOrderEventWorker.perform_async(order.id, :order_paid) if order.gift?
    Order::CreateVideoGiftMessageWorker.perform_async(order.id) if order.video_gift_fee.positive?
  end
end
