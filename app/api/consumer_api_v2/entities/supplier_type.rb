class ConsumerAPIV2::Entities::SupplierType < Grape::Entity
  expose :name
  expose :routable
  expose :exclusive
end
