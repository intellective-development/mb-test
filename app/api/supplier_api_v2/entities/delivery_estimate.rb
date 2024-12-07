# CK: Is this still applicable or should we change up how Delivery Estimates work?
#     Suggested refactor would be to continue having the DeliveryEstimate model on the server,
#     but have the client dynamically generate the option ranges based on shipment_method type and
#     maximum_delivery_expectation.
#
#     API would need to change to accept a maximum and minimum rather than id. Then we would do
#     a shipment.delivery_estimate = DeliveryEstimate.find_or_create_by(maximum: foo, minimum:  bar)
#

class SupplierAPIV2::Entities::DeliveryEstimate < Grape::Entity
  expose :id
  expose :description
end
