class SupplierAPIV2::Entities::Supplier::PackageSizePreset < Grape::Entity
  expose :id
  expose :dimensions
  expose :weight
  expose :bottle_count
end
