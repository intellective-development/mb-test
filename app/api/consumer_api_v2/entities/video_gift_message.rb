# frozen_string_literal: true

class ConsumerAPIV2::Entities::VideoGiftMessage < Grape::Entity
  expose :id
  expose :qr_code_url
  expose :recipient_notified
  expose :sender_notified
end
