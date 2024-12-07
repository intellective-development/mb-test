class ExternalAPIV1::Entities::Order::Status < Grape::Entity
  expose :order_number, &:number

  expose :state, as: :order_state
  expose :shipments, with: ExternalAPIV1::Entities::Order::Status::Shipment
end
