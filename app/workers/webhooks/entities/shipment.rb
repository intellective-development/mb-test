# frozen_string_literal: true

module Webhooks
  module Entities
    # Shipment entity for ShipmentUpdateWebhookWorker
    class Shipment < Grape::Entity
      format_with(:utc_iso_format) { |timestamp| timestamp&.utc&.iso8601 }
      format_with(:price_formatter) { |value| ((value&.to_f&.round_at(2) || 0.00) * 100).round }

      expose :id do |object|
        "#{object.order.number}_#{object.id}"
      end
      expose :supplierId do |object|
        object.supplier.id.to_s
      end
      expose :state, as: :status

      # TODO: Handle gift details information
      expose :firstName do |object|
        object.order.ship_address&.name&.split(' ')&.[](0)
      end
      expose :lastName do |object|
        object.order.ship_address&.name&.split(' ', 2)&.[](1)
      end
      expose :email do |object|
        object.order.email
      end
      expose :phone do |object|
        object.order.user&.account&.phone_number
      end
      expose :created_at, as: :createdAt, format_with: :utc_iso_format
      expose :updated_at, as: :updatedAt, format_with: :utc_iso_format
      expose :scheduled_for, as: :scheduledAt, format_with: :utc_iso_format
      expose :customer_placement, as: :customerPlacement
      expose :delivery_method_type, as: :deliveryType
      expose :delivery_fee, as: :deliveryFee, format_with: :price_formatter
      expose :shipment_sub_total, as: :subtotal, format_with: :price_formatter
      expose :shipment_discounts_total, as: :discounts, format_with: :price_formatter
      expose :bottle_deposit_fees, as: :bottleDepositFee, format_with: :price_formatter
      expose :shipment_taxed_amount, as: :taxes, format_with: :price_formatter
      expose :tip_share, as: :tip, format_with: :price_formatter
      expose :shipment_total_amount, as: :total, format_with: :price_formatter
      expose :attributes do |_|
        {
          gift: object.order.gift_detail.present?,
          outOfHours: object.out_of_hours,
          vip: object.order.vip?,
          scheduled: object.scheduled_for.present?,
          allowSubstitution: object.supplier.allow_substitution,
          engraving: object.order.order_items.any? { |item| item.item_options.instance_of? EngravingOptions }
        }
      end
      expose :comments, with: Webhooks::Entities::Comment
      expose :gift do |object|
        if object.order.gift_detail.present?
          gift_detail = object.order.gift_detail
          {
            firstName: gift_detail.recipient_name&.split(' ')&.[](0),
            lastName: gift_detail.recipient_name&.split(' ', 2)&.[](1),
            phone: gift_detail.recipient_phone,
            email: gift_detail.recipient_email
          }
        else
          {}
        end
      end
      expose :address, with: Webhooks::Entities::Address
      expose :packages, with: Webhooks::Entities::Package
      expose :order_items, as: :items, with: Webhooks::Entities::ShipmentItem
      expose :partner do |object|
        {
          name: object.order.storefront.name,
          logoUrl: object.order.storefront.logo_url
        }
      end

      expose :timeline do |shipment|
        shipment.shipment_transitions.map do |transition|
          {
            status: transition.to_state,
            date: transition.created_at
          }
        end
      end

      def delivery_method_type
        return 'shipped' if object.shipped?
        return 'pickup' if object.pickup?
        return 'onDemand' if object.on_demand?

        'digital'
      end
    end
  end
end
