class SupplierAPIV2::Entities::Me < Grape::Entity
  expose :name
  expose :email
  expose :supplier, with: SupplierAPIV2::Entities::Supplier
end
