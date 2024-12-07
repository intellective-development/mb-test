class VideoGiftMessage::NotifyRecipientService
  def initialize(video_gift_message_id:)
    @video_gift_message = VideoGiftMessage.find(video_gift_message_id)
  end

  def call
    notify_recipient
  end

  private

  def notify_recipient
    segment_service = Segments::SegmentService.from(@video_gift_message.order.storefront)
    recipient_notified = segment_service.video_gift_order_message_recorded(@video_gift_message)

    @video_gift_message.update_column(:recipient_notified, true) if recipient_notified
  end
end
