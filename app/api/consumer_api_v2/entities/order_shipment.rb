class ConsumerAPIV2::Entities::OrderShipment < Grape::Entity
  expose :shipment_state, as: :state
  expose :supplier, with: ConsumerAPIV2::Entities::SupplierAddress
  expose :shipping_method_type, &:shipping_type

  expose :status_action, with: ConsumerAPIV2::Entities::OrderStatusAction do |shipment|
    shipment.shipping_method&.trackable? ? shipment : nil
  end

  expose :order_item_ids do |shipment|
    shipment.order_items.map(&:variant_id)
  end

  format_with(:price_formatter) { |value| value&.to_f&.round_at(2) }
  expose :shipment_total_amount, as: :total, format_with: :price_formatter

  expose :order_adjustments, as: :adjustments, with: SupplierAPIV2::Entities::Adjustment do |object|
    # Substitution.confim since Nov 15, 2019 will add its own id to the OrderAdjustment it creates.
    # For OrderAdjustments created as a result of Substitution.confirm before the change mentioned above,
    # we will attempt 'smart matching' by adjustment reason and amount.
    substitution_reason_ids = OrderAdjustmentReason.where('name like ?', 'Item Replacement%').map(&:id)
    object.order_adjustments.where(financial: true, substitution_id: nil).select do |adjustment|
      # If adjustment is not due to item replacement, pass it through.
      next true unless substitution_reason_ids.include?(adjustment.reason_id)

      # Basically we are checking if the amount seen in this adjustment matches any of the substitution (both rounded to US cent).
      adjustment_amount = (adjustment.amount || 0) * (adjustment.credit ? -1 : 1)
      object.substitutions.all? do |substitution|
        from = substitution.original
        to = substitution.substitute

        # then check if they adjust the same amount
        substitution_amount = (to.total - from.total) + (to.tax_charge_with_bottle_deposits - from.tax_charge_with_bottle_deposits)
        (substitution_amount * 100).round != (adjustment_amount * 100).round
      end
    end
  end

  expose :shipment_amount, with: ConsumerAPIV2::Entities::ShipmentAmount

  def shipment_state
    if object.shipped? && object.state == 'delivered'
      'shipped'
    elsif object.order.state == 'canceled'
      'canceled'
    else
      object.state
    end
  end
end
