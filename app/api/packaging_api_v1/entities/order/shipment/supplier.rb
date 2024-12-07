class PackagingAPIV1::Entities::Order::Shipment::Supplier < Grape::Entity
  expose :display_name, as: :name
end
