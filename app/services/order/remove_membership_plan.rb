class Order::RemoveMembershipPlan
  def initialize(order:, user:, force: false)
    @order = order
    @user = user
    @force = force
  end

  def call
    Order::FINISHED_STATES.include?(order.state) ? remove_membership_plan_on_finished_order : remove_membership_plan

    self
  end

  def success?
    @success
  end

  attr_reader :order, :user, :force, :error

  private

  def remove_membership_plan_on_finished_order
    return order_finished_error unless refund_membership?

    values_with_membership

    return unless refund_membership.success?

    remove_membership_plan

    charge_membership_discounts
  end

  def order_finished_error
    @error = "This order is finished, we can't remove the membership_plan."
  end

  def remove_membership_plan
    @success = Order.transaction do
      order.update(membership_plan: nil, membership: nil)
      raise ActiveRecord::Rollback unless order.recalculate_and_apply_taxes

      true
    rescue ActiveRecord::RecordInvalid
      raise ActiveRecord::Rollback
    end
  end

  def values_with_membership
    @values_with_membership ||= {
      order_values: {
        membership_tax: order.membership_tax.to_f,
        service_fee_discount: order.membership_service_fee_discount.to_f
      },
      shipment_values: store_shipments_values_with_membership
    }
  end

  def store_shipments_values_with_membership
    shipment_values = {}
    order.shipments.map do |shipment|
      shipment_values[shipment.id] = {
        total_supplier_charge: shipment.total_supplier_charge.to_f,
        total_minibar_charge: shipment.total_minibar_charge.to_f
      }
    end
    shipment_values
  end

  def charge_membership_discounts
    order.reload
    minibar_charges = order.membership_tax.to_f - values_with_membership[:order_values][:membership_tax]
    minibar_charges += values_with_membership[:order_values][:service_fee_discount] - order.membership_service_fee_discount.to_f

    default_params = {
      reason_id: OrderAdjustmentReason.find_by_name('Order Change - Item Removed from Order (Not OOS, Customer Requested)').id,
      description: 'Removing membership purchase on finished order.',
      user_id: user.id
    }

    order.shipments.each do |shipment|
      previous_total_supplier_charge = values_with_membership[:shipment_values][shipment.id][:total_supplier_charge]
      supplier_charges = shipment.total_supplier_charge.to_f - previous_total_supplier_charge

      previous_total_minibar_charge = values_with_membership[:shipment_values][shipment.id][:total_minibar_charge]
      minibar_charges += shipment.total_minibar_charge.to_f - previous_total_minibar_charge

      next if supplier_charges.zero?

      params = { amount: supplier_charges.round(2).abs, financial: true, credit: supplier_charges.negative? }.merge(default_params)
      OrderAdjustmentCreationService.new(shipment, params).process_now!
      shipment.save!
    end

    params = { amount: minibar_charges.round(2).abs, financial: true, credit: minibar_charges.negative? }.merge(default_params)
    shipment = order.shipments.first
    OrderAdjustmentCreationService.new(shipment, params, true).process_now!
    shipment.save!
  end

  def refund_membership
    Memberships::Refund.new(membership: order.membership).call
  end

  def refund_membership?
    force || order.membership.present?
  end
end
