class ExternalAPIV1::Entities::Order::Status::Shipment < Grape::Entity
  expose :uuid
  expose :state
  expose :packages, with: ExternalAPIV1::Entities::Order::Status::Shipment::Status::Package
end
