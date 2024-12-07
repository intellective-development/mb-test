# frozen_string_literal: true

# Retailer shipments entity
class RetailerAPIV1::Entities::Shipments < Grape::Entity
  format_with(:supplier_timezone) { |timestamp| timestamp&.in_time_zone(object.supplier.timezone)&.iso8601 }
  format_with(:price_formatter) { |value| (value * 100).to_i }

  expose :id do |shipment|
    [shipment.order.number, shipment.id].join('_')
  end

  expose :state, as: :status
  expose :firstName do |shipment|
    shipment.user&.first_name
  end
  expose :lastName do |shipment|
    shipment.user&.last_name
  end
  expose :created_at, as: :createdAt
  expose :updated_at, as: :updatedAt
  expose :shipping_type, as: :deliveryType
  expose :customer_placement, as: :customerPlacement
  expose :total, as: :total, format_with: :price_formatter
  expose :attributes do
    expose :gift?, as: :gift
    expose :out_of_hours, as: :outOfHours
    expose :vip do |shipment|
      shipment.order.vip?
    end
    expose :corporate do |shipment|
      shipment.order.corporate?
    end
    expose :scheduled do |shipment|
      shipment.scheduled_for.present?
    end
    expose :allowSubstitution do |shipment|
      shipment.order.allow_substitution?
    end
    expose :engraving?, as: :engraving
  end
  expose :order_items, as: :items, with: RetailerAPIV1::Entities::Shipments::Item
  expose :partner do
    expose :name do |shipment|
      shipment.order.storefront.name
    end
  end
end
