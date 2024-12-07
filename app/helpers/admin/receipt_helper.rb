module Admin::ReceiptHelper
  def receipt_substitutions(refresh: false)
    @order_substitutions = if @order_substitutions.nil? || refresh
                             @order.shipments
                                   .map(&:substitutions)
                                   .flatten.compact
                           else
                             @order_substitutions
                           end
  end

  def receipt_non_substitution_adjustments
    # Substitution.confim will now add its own id to the OrderAdjustment it creates.
    non_substitution_adjustments = @order.order_adjustments.where(financial: true, substitution_id: nil)

    # Let's attempt to filter out OrderAdjustments created as a result of Substitution.confirm before the change mentioned above.
    substitution_reason_ids = OrderAdjustmentReason.where('name like ?', 'Item Replacement%').pluck(:id)

    non_substitution_adjustments = non_substitution_adjustments.select do |adjustment|
      # If adjustment is not due to item replacement, pass it through.
      next true unless substitution_reason_ids.include?(adjustment.reason_id)

      # Basically we are checking if the amount seen in this adjustment matches any of the substitution (both rounded to US cent).
      adjustment_amount = (adjustment.amount || 0) * (adjustment.credit ? -1 : 1)
      receipt_substitutions.all? do |substitution|
        from = substitution.original
        to = substitution.substitute

        # ignore if they are not from the same shipment
        next true if to.shipment_id != adjustment.shipment_id

        # then check if they adjust the same amount
        substitution_amount = (to.total - from.total) + (to.tax_charge_with_bottle_deposits - from.tax_charge_with_bottle_deposits)
        (substitution_amount * 100).round != (adjustment_amount * 100).round
      end
    end
  end
end
