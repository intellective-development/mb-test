class SupplierAPIV2::Entities::NotificationMethod < Grape::Entity
  expose :active
  expose :id
  expose :label
  expose :notification_type
  expose :value
end
