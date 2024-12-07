class LambdaAPIV1::Entities::GiftCardImage < Grape::Entity
  expose :id
  expose :correlation_id
  expose :status
  expose :image_url
  expose :thumb_url
end
