class SupplierAPIV2::Entities::CustomTag < Grape::Entity
  expose :id
  expose :name
  expose :color
  expose :description
end
