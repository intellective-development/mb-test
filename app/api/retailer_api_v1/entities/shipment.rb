# frozen_string_literal: true

# Retailer shipment entity
class RetailerAPIV1::Entities::Shipment < Grape::Entity
  format_with(:price_formatter) { |value| (value * 100).to_i }

  expose :id do |shipment|
    [shipment.order.number, shipment.id].join('_')
  end

  expose :state, as: :status
  expose :firstName do |shipment|
    shipment.user.first_name
  end
  expose :lastName do |shipment|
    shipment.user.last_name
  end
  expose :phone do |shipment|
    shipment.user.shipping_addresses&.last&.phone || shipment.user&.account&.phone_number
  end
  expose :created_at, as: :createdAt
  expose :updated_at, as: :updatedAt
  expose :scheduled_for, as: :scheduledAt
  expose :customer_placement, as: :customerPlacement
  expose :shipping_type, as: :deliveryType
  expose :delivery_fee, as: :deliveryFee, format_with: :price_formatter
  expose :sub_total, as: :subtotal, format_with: :price_formatter
  expose :discounts_total, as: :discounts, format_with: :price_formatter
  expose :bottle_deposit_fees, as: :bottleDepositFee, format_with: :price_formatter
  expose :taxes do |shipment|
    (shipment.shipment_amount&.taxed_amount&.* 100).to_i
  end
  expose :tip_share, as: :tip, format_with: :price_formatter
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
  expose :comments, with: RetailerAPIV1::Entities::Comment
  expose :gift do
    expose :firstName do |shipment|
      shipment.gift_detail&.recipient_name
    end
    expose :lastName do |shipment|
      shipment.gift_detail&.recipient_name
    end
    expose :phone do |shipment|
      shipment.gift_detail&.recipient_phone
    end
    expose :message do |shipment|
      shipment.gift_detail&.message
    end
  end
  expose :address do
    expose :address1 do |shipment|
      shipment.address.address1
    end
    expose :address2 do |shipment|
      shipment.address.address2
    end
    expose :city do |shipment|
      shipment.address.city
    end
    expose :state do |shipment|
      shipment.address.state_name
    end
    expose :country do |shipment|
      shipment.address.country
    end
    expose :zip do |shipment|
      shipment.address.zip_code
    end
  end
  expose :packages, with: RetailerAPIV1::Entities::Package
  expose :order_items, as: :items, with: RetailerAPIV1::Entities::Item
  expose :partner do
    expose :name do |shipment|
      shipment.order.storefront.name
    end
    expose :logoUrl do |shipment|
      shipment.order.storefront.logo_url
    end
  end
  expose :timeline do |shipment|
    shipment.shipment_transitions.map do |transition|
      {
        status: transition.to_state,
        date: transition.created_at
      }
    end
  end
end
