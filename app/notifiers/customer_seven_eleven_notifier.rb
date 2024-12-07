class CustomerSevenElevenNotifier < BaseNotifier
  def out_of_stock_notification(shipment_id)
    @shipment   = Shipment.find(shipment_id)
    @order      = @shipment.order
    @recipient  = @order.user
    return unless @order.minibar?

    refunds = OrderAdjustment.where(shipment_id: shipment_id, credit: true, user_id: RegisteredAccount.seven_eleven.user.id)
    refunded_items = []
    refunded_total = 0.0

    # there's no direct connection to removed item, so we fetch the data from description
    # Description: Order Item removed: 1 Coors Light at $8.59 for a total $8.59.
    item_re = /Item removed: (\d+) (.*?) at/

    refunds.each do |r|
      item_parts = r.description.scan(item_re).first
      refunded_items.push(item_parts.last) if item_parts.present?
      refunded_total += r.amount.to_f
    end

    @shipment.substitutions.each do |s|
      original_item = s.original
      substituted_item = s.substitute
      remaining_item = s.remaining_item

      cost_diff = substituted_item.total - original_item.total + (remaining_item&.total || 0)
      tax_diff = substituted_item.tax_charge_with_bottle_deposits - original_item.tax_charge_with_bottle_deposits + (remaining_item&.tax_charge_with_bottle_deposits || 0)
      total_diff = cost_diff + tax_diff

      qty_diff = original_item.quantity - substituted_item.quantity

      refunded_items.push("#{qty_diff} #{original_item.variant.name}")
      refunded_total += total_diff.abs.to_f
    end

    @items = refunded_items.join(', ') unless refunded_items.empty?
    @total = refunded_total.to_f.round_at(2) if refunded_total.positive?

    mail(from: 'Minibar Delivery <help@minibardelivery.com>',
         to: @recipient.email_address_with_name,
         subject: format_subject("Item(s) removed from Minibar Delivery Order ##{@order.number}")) do |format|
      format.html { render layout: 'email_ink' }
    end
  end

  def cancellation_notification(shipment_id)
    @shipment   = Shipment.find(shipment_id)
    @order      = @shipment.order
    @recipient  = @order.user

    unless @order.storefront.default_storefront?
      # We should never get there, because corresponding button should not be displayed for non-Minibar shipments
      raise 'This method could only be called for Minibar storefront'
    end

    @coupon_code = CouponValue.generate_seven_eleven_reward.code

    mail(from: 'Minibar Delivery <help@minibardelivery.com>',
         to: @recipient.email_address_with_name,
         subject: format_subject("7-Eleven Shipment from Minibar Delivery Order ##{@order.number} has been canceled")) do |format|
      format.html { render layout: 'email_ink' }
    end
  end

  def failed_delivery_notification(shipment_id)
    @shipment   = Shipment.find(shipment_id)
    @order      = @shipment.order
    return unless @order.minibar?

    @recipient  = @order.user
    @address    = [@order.ship_address.address_lines, @order.ship_address.city].join(', ')
    @phone      = @order.ship_address.phone

    failed_shipment = @shipment.shipment_transitions.select { |s| s&.to_state == 'canceled' }.first
    @date = (failed_shipment&.created_at || DateTime.current).in_time_zone(@shipment.try(:supplier).try(:timezone))

    mail(from: 'Minibar Delivery <help@minibardelivery.com>',
         to: @recipient.email_address_with_name,
         subject: format_subject("7-Eleven Shipment from Minibar Delivery Order ##{@order.number} was undeliverable")) do |format|
      format.html { render layout: 'email_ink' }
    end
  end
end
