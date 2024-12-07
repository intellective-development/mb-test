class SupplierAPIV2::Entities::Shipment < Grape::Entity
  format_with(:supplier_timezone) { |timestamp| timestamp&.in_time_zone(object.supplier.timezone)&.iso8601 }
  format_with(:price_formatter) { |value| value&.to_f&.round_at(2) }

  expose :uuid, as: :id
  expose :order_number, as: :number
  expose :supplier_dash_state, as: :state
  expose :supplier_delivery_notes, as: :notes
  expose :metadata_driver_id, as: :driver_id
  expose :engraving?, as: :has_engraving
  expose :custom_tags, with: SupplierAPIV2::Entities::CustomTag

  expose :delivery_method do
    expose :type, &:shipping_type
    expose :estimated_delivery_expectation, if: :metadata, safe: true do |shipment|
      shipment.metadata.delivery_estimate_in_minutes
    end
    expose :maximum_delivery_expectation do |shipment|
      shipment.shipping_method.maximum_delivery_expectation
    end
  end

  with_options(format_with: :supplier_timezone) do
    expose :created_at do |shipment|
      if shipment.order.completed_at.present?
        shipment.order.completed_at.in_time_zone(shipment.supplier.timezone)&.iso8601
      else
        shipment.created_at.in_time_zone(shipment.supplier.timezone)&.iso8601
      end
    end
    expose :confirmed_at
    expose :canceled_at
    expose :delivered_at
    expose :en_route_at
    expose :scheduled_for,     if: ->(instance, _options) { instance.scheduled_for }
    expose :scheduled_for_end, if: ->(instance, _options) { instance.scheduled_for } do |shipment|
      window_size = shipment.shipping_method.scheduled_interval_size.minutes
      (shipment.scheduled_for + window_size)&.in_time_zone(shipment.supplier.timezone)&.iso8601 if shipment.scheduled_for.present?
    end
    expose :order_time do |shipment|
      (shipment.scheduled_for.presence || shipment.order.completed_at)&.in_time_zone(shipment.supplier.timezone)&.iso8601 if (shipment.scheduled_for.presence || shipment.order.completed_at).present?
    end
  end

  expose :is_pre_sale, &:customer_placement_pre_sale?

  expose :is_back_order, &:customer_placement_back_order?

  expose :is_standard, &:customer_placement_standard?

  expose :customer_placement, &:customer_placement

  expose :amounts do
    with_options(format_with: :price_formatter) do
      expose :shipment_total_amount, as: :total
      expose :shipment_sub_total, as: :subtotal
      expose :shipment_bottle_deposits, as: :bottle_fee
      expose :shipment_tax_discounting_bottle_fee, as: :tax_no_bottle_fee
      expose :shipment_taxed_amount, as: :tax
      expose :shipment_tip_amount, as: :tip
      expose :shipment_minibar_funded_discounts, as: :minibar_promos
      expose :shipment_supplier_funded_discounts, as: :store_discounts
      expose :shipment_shipping_charges, as: :delivery_fee
    end
  end

  expose :extras, &:shipment_supplier_extras

  expose :billing do
    expose :cc_type do |shipment|
      shipment.order&.payment_profile&.cc_type
    end
    expose :last_digits do |shipment|
      shipment.order&.payment_profile&.last_digits
    end
  end

  expose :birthdate do |shipment|
    shipment.order.birthdate
  end

  expose :pickup_detail, if: ->(instance, _options) { instance.pickup? }, with: SupplierAPIV2::Entities::PickupDetail
  expose :address, if: ->(instance, _options) { !instance.pickup? }, with: SupplierAPIV2::Entities::Address

  expose :recipient_info do
    expose :short_recipient_name, as: :short_name
    expose :long_recipient_name, as: :long_name
    expose :recipient_phone, as: :phone
  end
  expose :customer_name do |shipment|
    shipment.order.user.name
  end

  expose :gift_message, if: ->(instance, _options) { instance.order.gift? } do |shipment|
    shipment.gift_detail&.message
  end

  expose :type_tags do |shipment|
    {
      gift: shipment.order.gift?,
      out_of_hours: shipment.out_of_hours,
      vip: shipment.order.vip?,
      corporate: shipment.order.user.company_name,
      scheduled: shipment.scheduled_for.present?,
      allow_substitution: shipment.order.allow_substitution,
      new_customer: shipment.order.user.orders.finished.count < 2,
      engraving: shipment.engraving?
    }
  end

  expose :order_items, with: SupplierAPIV2::Entities::OrderItem
  expose :comment_ids do |shipment|
    shipment.comments.order(created_at: :asc).pluck(:id)
  end
  expose :order_adjustment_ids do |shipment|
    shipment.order_adjustments.order(created_at: :asc).pluck(:id)
  end
  expose :use_delivery_service?, as: :using_delivery_service
  expose :delivery_service
  expose :show_dsp_flipper

  expose :primary_delivery_service, with: SupplierAPIV2::Entities::DeliveryService do |shipment|
    shipment.supplier.delivery_service
  end
  expose :secondary_delivery_service, with: SupplierAPIV2::Entities::DeliveryService do |shipment|
    shipment.supplier.secondary_delivery_service
  end

  expose :tracking_details do |shipment|
    {
      carrier: shipment.tracking_detail&.carrier,
      tracking_number: shipment.tracking_detail&.reference
    }
  end

  expose :substitutions, with: SupplierAPIV2::Entities::Substitution
  expose :customer_placement
  expose :packages, with: SupplierAPIV2::Entities::Package

  expose :storefront do |shipment|
    {
      id: shipment.order&.storefront&.id,
      name: shipment.order&.storefront&.business&.name,
      logo_url: shipment.order&.storefront&.logo_url,
      favicon_url: shipment.order&.storefront&.favicon_url
    }
  end

  # private
end
