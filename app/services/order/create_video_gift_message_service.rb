class Order::CreateVideoGiftMessageService
  def initialize(order_id:)
    @order = Order.find(order_id)
  end

  def call
    create_video_gift_message
    notify_sender
    send_video_gift_order_created_event
  end

  private

  def create_video_gift_message
    ClipjoyService.new(@order).notify_purchase
  end

  def notify_sender
    segment_service = Segments::SegmentService.from(@order.storefront)
    video_gift_message = @order.reload.video_gift_message

    sender_notified = segment_service.video_gift_order_recording_requested(video_gift_message)

    video_gift_message.update_column(:sender_notified, true) if sender_notified
  end

  def send_video_gift_order_created_event
    Order::SendVideoGiftOrderCreatedEventWorker.perform_async(@order.id)
  end
end
