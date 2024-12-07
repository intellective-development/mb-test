class ClipjoyWebhooks < BaseAPI
  namespace :video do
    desc 'Webhook endpoint for Clipjoy to notify us when a user records a video.'
    post :recorded do
      body = request.body.read

      error!("Request body cannot be blank. Please include 'uniqueTagId' in it", 400) if body.blank?

      parsed_body = JSON.parse(body)
      unique_tag_id = parsed_body.fetch('uniqueTagId')
      video_gift_message = VideoGiftMessage.find_by(video_tag_id: unique_tag_id)

      if video_gift_message.nil?
        status 200
        return
      end

      VideoGiftMessage::NotifyRecipientWorker.perform_async(video_gift_message.id) if video_gift_message.order.digital?

      status 200
    end
  end
end
