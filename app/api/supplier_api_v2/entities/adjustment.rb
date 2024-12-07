class SupplierAPIV2::Entities::Adjustment < Grape::Entity
  format_with(:price_formatter) { |value| value&.to_f&.round_at(2) }
  format_with(:supplier_timezone) { |timestamp| timestamp&.in_time_zone(object.supplier.timezone)&.iso8601 }

  expose :id
  expose :description
  expose :created_at, format_with: :supplier_timezone
  expose :amount, format_with: :price_formatter
  expose :credit
  expose :reason_name, as: :reason
end
