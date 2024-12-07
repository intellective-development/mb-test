class SupplierAPIV2::Entities::ShipmentListItem < Grape::Entity
  format_with(:supplier_timezone) { |timestamp| timestamp&.in_time_zone(object.supplier.timezone)&.iso8601 }
  format_with(:price_formatter) { |value| value&.to_f&.round_at(2) }

  expose :uuid, as: :id

  expose :number do |shipment|
    shipment.order.number
  end

  expose :supplier_dash_state, as: :state
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
    expose :canceled_at
    expose :scheduled_for,     if: ->(instance, _options) { instance.scheduled_for }
    expose :scheduled_for_end, if: ->(instance, _options) { instance.scheduled_for } do |shipment|
      window_size = shipment.shipping_method.scheduled_interval_size.minutes
      (shipment.scheduled_for + window_size)&.in_time_zone(shipment.supplier.timezone)&.iso8601 if shipment.scheduled_for.present?
    end
    expose :order_time do |shipment|
      (shipment.scheduled_for.presence || shipment.order.completed_at)&.in_time_zone(shipment.supplier.timezone)&.iso8601 if (shipment.scheduled_for.presence || shipment.order.completed_at).present?
    end
  end

  expose :amounts do
    with_options(format_with: :price_formatter) do
      expose :shipment_total_amount, as: :total
    end
  end

  expose :type_tags do |shipment|
    {
      gift: shipment.order.gift?,
      out_of_hours: shipment.out_of_hours,
      vip: shipment.order.vip?,
      corporate: shipment.user&.company_name,
      scheduled: shipment.scheduled_for.present?,
      allow_substitution: shipment.order.allow_substitution,
      new_customer: shipment.user.present? && shipment.user.orders.finished.count < 2,
      engraving: shipment.engraving?
    }
  end

  expose :recipient_info do
    expose :short_recipient_name, as: :short_name
    expose :long_recipient_name, as: :long_name
    expose :recipient_phone, as: :phone
  end

  expose :customer_name do |shipment|
    shipment.order.user&.name
  end

  expose :order_items do |shipment|
    shipment.order_items.map do |item|
      {
        sku: item.variant&.sku,
        name: item.variant&.product_trait_name,
        volume: item.product&.item_volume,
        quantity: item.quantity,
        unit_price: item.price&.to_f&.round_at(2)
      }
    end
  end

  expose :comment_ids do |shipment|
    shipment.comments.order(created_at: :asc).pluck(:id)
  end

  expose :use_delivery_service?, as: :using_delivery_service

  expose :delivery_service, with: SupplierAPIV2::Entities::DeliveryService do |shipment|
    shipment.supplier.delivery_service
  end

  expose :secondary_delivery_service, with: SupplierAPIV2::Entities::DeliveryService do |shipment|
    shipment.supplier.secondary_delivery_service
  end

  expose :storefront do |shipment|
    {
      name: shipment.order&.storefront&.name,
      favicon_url: shipment.order&.storefront&.favicon_url
    }
  end

  expose :packages, with: SupplierAPIV2::Entities::Package

  private

  def short_recipient_name
    return nil unless object.user.present?

    object.short_recipient_name
  end

  def long_recipient_name
    return nil unless object.user.present?

    object.long_recipient_name
  end
end
