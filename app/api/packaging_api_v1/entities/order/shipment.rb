class PackagingAPIV1::Entities::Order::Shipment < Grape::Entity
  expose :state
  expose :supplier, with: PackagingAPIV1::Entities::Order::Shipment::Supplier
  expose :order_items, with: PackagingAPIV1::Entities::Order::Shipment::OrderItem
  expose :packages, with: PackagingAPIV1::Entities::Order::Shipment::Package
end
