class SupplierAPIV2::Entities::Package < Grape::Entity
  expose :uuid, as: :id
  expose :carrier
  expose :label_url
  expose :tracking_number
  expose :tracking_url
end
