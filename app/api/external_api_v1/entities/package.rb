class ExternalAPIV1::Entities::Package < Grape::Entity
  format_with(:iso_timestamp) { |dt| dt&.iso8601 }

  expose :tracking_number
  expose :tracking_url
  expose :state
  expose :shipping_date
  expose :expected_delivery_date, format_with: :iso_timestamp
  expose :carrier
end
