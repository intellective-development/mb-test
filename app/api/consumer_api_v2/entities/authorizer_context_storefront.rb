class ConsumerAPIV2::Entities::AuthorizerContextStorefront < Grape::Entity
  expose :id
  expose :business_id

  expose :is_minibar do |storefront|
    storefront&.default_storefront?
  end
end
