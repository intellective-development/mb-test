class PackagingAPIV1::Entities::Order::Shipment::Package < Grape::Entity
  expose :tracking_number
  expose :tracking_url
  expose :carrier_tracking_url
  expose :carrier
  expose :state
  expose :expected_delivery_date

  def expected_delivery_date
    object.expected_delivery_date&.to_datetime&.iso8601
  end
end
