class VideoGiftMessage::NotifyRecipientWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(video_gift_message_id)
    VideoGiftMessage::NotifyRecipientService.new(video_gift_message_id: video_gift_message_id).call
  end
end
