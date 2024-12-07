class SupplierAPIV2::Entities::Substitution < Grape::Entity
  expose :id, :status, :original_id, :substitute_id
  expose :substitute, with: SupplierAPIV2::Entities::OrderItem
  expose :original, with: SupplierAPIV2::Entities::OrderItem
end
