class ConsumerAPIV2::Entities::Business < Grape::Entity
  expose :id
  expose :name
  expose :service_fee
  expose :price_rounding
end
