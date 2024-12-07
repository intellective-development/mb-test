class ConsumerAPIV2::Entities::GiftDetails < Grape::Entity
  expose :id
  expose :recipient_name
  expose :recipient_email
  expose :recipient_phone
  expose :message
end
