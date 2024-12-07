class ConsumerAPIV2::Entities::GiftCardImage < Grape::Entity
  expose :id
  expose :correlation_id
  expose :image_url
  expose :thumb_url
end
