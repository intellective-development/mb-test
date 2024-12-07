# frozen_string_literal: true

class InternalAPIV1
  module Entities
    # InternalAPIV1::Entities::OrderShipment
    class OrderShipment < Grape::Entity
      expose :state
      expose :customer_placement
      expose :supplier, with: InternalAPIV1::Entities::Supplier
      expose :shipping_method, with: InternalAPIV1::Entities::ShippingMethod

      format_with(:price_formatter) { |value| value&.to_f&.round_at(2) }
      expose :shipment_total_amount, as: :total, format_with: :price_formatter

      format_with(:iso_timestamp) { |dt| dt&.iso8601 }
      expose :created_at, format_with: :iso_timestamp
      expose :updated_at, format_with: :iso_timestamp

      expose :pickup_detail, if: ->(instance, _options) { instance.pickup? }
      expose :delivery_detail, if: ->(instance, _options) { instance.on_demand? }
      expose :packages, with: InternalAPIV1::Entities::Package, if: ->(instance, _options) { instance.shipped? }

      expose :shipment_amount, with: InternalAPIV1::Entities::ShipmentAmount

      expose :order_items, as: :items, with: InternalAPIV1::Entities::OrderItem do |shipment|
        shipment.order_items.group_by { |item| item.identifier&.to_i || item.variant_id }.to_a
      end

      expose :comments, with: InternalAPIV1::Entities::Comment

      def delivery_method_type
        return 'shipping' if object.shipped?
        return 'pickup' if object.pickup?
        return 'on_demand' if object.on_demand?

        'digital'
      end

      def pickup_detail
        return unless object.pickup?

        {
          name: object.pickup_detail&.name,
          phone: object.pickup_detail&.phone
        }
      end

      def delivery_detail
        return unless object.on_demand?

        {
          delivery_order_id: object.external_order_id,
          delivery_service_order: object.delivery_service&.name
        }
      end
    end
  end
end
