class Order::Amounts
  attr_accessor :video_gift_fee
  attr_reader :order

  def initialize(order, order_amount = nil)
    @order = order
    @video_gift_fee = order_amount ? order_amount.video_gift_fee : 0.0
    @order_amount = order_amount
  end

  def shipping_charges
    shipments.sum(&:shipment_shipping_charges).to_f.round_at(2)
  rescue StandardError
    shipments.sum(&:delivery_fee).to_f.round_at(2)
  end

  def delivery_fee_discounts_total
    shipments.map { |s| s.shipment_amount&.delivery_fee_discounts_total.to_f }.sum(0).to_f.round_at(2)
  end

  def shipping_fee_discounts_total
    shipments.map { |s| s.shipment_amount&.shipping_fee_discounts_total.to_f }.sum(0).to_f.round_at(2)
  end

  def delivery_charges
    shipping = {
      shipping: 0.0,
      on_demand: 0.0
    }
    shipments.each do |shipment|
      if shipment.shipping_method&.shipped?
        shipping[:shipping] += shipment.shipment_shipping_charges || 0.0
      elsif shipment.shipping_method&.on_demand?
        shipping[:on_demand] += shipment.shipment_shipping_charges || 0.0
      end
    end
    shipping[:shipping] = shipping[:shipping].to_f.round_at(2)
    shipping[:on_demand] = shipping[:on_demand].to_f.round_at(2)
    shipping
  end

  def shipping_after_discounts
    return 0 if @order.free_shipping_coupon?

    delivery_charges[:shipping] - shoprunner_total
  end

  def delivery_after_discounts
    return 0 if @order.free_delivery_coupon?

    delivery_charges[:on_demand]
  end

  def shipping_tax
    shipments.sum(&:shipping_tax).to_f.round_at(2)
  end

  def order_items_total
    shipments.sum(&:sub_total).to_f.round_at(2)
  end

  def bag_fee
    shipments.sum(&:bag_fee).to_f.round_at(2)
  end

  def deals_total
    shipments.sum(&:deals_amount).to_f.round_at(2)
  end

  def shoprunner_total
    shipments.sum(&:shoprunner_amount).to_f.round_at(2)
  end

  def fulfillment_fee
    shipments.sum { |s| s.shipment_fulfillment_fee.to_f }
  end

  def discounts_total
    [
      coupon_amount,
      deals_total,
      shoprunner_total,
      membership_engraving_fee_discount,
      membership_plan&.no_service_fee? ? service_fee_discounts : 0
    ].sum.to_f.round_at(2)
  end

  def order_items_tax
    shipments.sum(&:order_items_tax).to_f.round_at(2)
  end

  def additional_tax
    0.0
  end

  # TODO: JM: For CRV deposit totals.
  # note: bottle deposits for 7eleven are already included in shipment additional_tax
  def bottle_deposits
    shipments.sum(&:bottle_deposit_fees).to_f.round_at(2)
  end

  def tip_amount
    @order[:tip_amount].to_s.to_d
  end

  def tip_eligible_amount
    shipments.select { |s| s.shipping_method.allows_tipping? }.sum(&:sub_total)
  end

  def sub_total
    # bottle deposits are already included on total tax_charge
    order_items_total
  end

  # This actually means total_tax
  def taxed_amount
    (order_items_tax + bottle_deposits + shipping_tax + bag_fee + additional_tax + membership_tax)
  end

  def sub_total_with_engraving
    sub_total + engraving_fee
  end

  def sales_tax
    @sales_tax ||= order_items_tax + membership_tax + shipping_tax
  end

  # vgm fee is handled as special fee and it should not be here
  def total_taxed_amount
    @total_taxed_amount ||= taxed_amount + service_fee + retail_delivery_fee
  end

  def tax_discounting_bottle_fee
    taxed_amount - bottle_deposits
  end

  def order_credit_card_balance
    shipments.sum { |shipment| shipment&.initial_charge&.balance || 0.0 }
  end

  def engraving_fee
    shipments.sum(&:engraving_fee_without_discounts).to_f.round_at(2)
  end

  def engraving_fee_discounts
    shipments.sum(&:engraving_fee_discounts).to_f.round_at(2)
  end

  def engraving_fee_discounts_without_membership_discount
    engraving_fee_discounts - membership_engraving_fee_discount
  end

  def engraving_fee_after_discounts
    shipments.sum(&:engraving_fee).to_f.round_at(2)
  end

  def service_fee
    if @order.liquid
      @order_amount&.service_fee || 0
    else
      ServiceFeeCalculator.new(@order).fee_amount
    end
  end

  def potential_membership_savings
    return [] if membership?

    discounts = MembershipPlan.active.where(storefront_id: @order.storefront_id).map do |plan|
      { membership_plan_id: plan.id, discount: membership_discount_calculation(plan) }
    end
    discounts.sort_by { |plan| -plan[:discount] }
  end

  def membership_discount
    return 0.0 unless membership?

    membership_discount_calculation
  end

  def membership_discount_calculation(plan = nil)
    membership_discount = 0.0
    membership_discount += membership_service_fee_discount(plan)
    # we use calc for potential_membership_savings instead of engraving_fee_discounts
    membership_discount += membership_engraving_fee_discount(plan)
    # we delivery_charges use for potential_membership_savings usage
    membership_discount += membership_shipping_discount(plan)
    membership_discount += membership_on_demand_discount(plan)
    membership_discount
  end

  def membership_price
    @order.membership_plan&.price.to_f
  end

  def membership?
    !!membership_plan
  end

  def membership_plan
    @order.membership_plan_record
  end

  def membership_tax
    @membership_tax ||= @order.local_membership_tax || 0.0
  end

  def membership_service_fee_discount(plan = nil)
    plan ||= membership_plan
    plan&.no_service_fee? ? service_fee : 0.0
  end

  def membership_engraving_fee_discount(plan = nil)
    plan ||= membership_plan

    return 0.0 unless plan&.apply_engraving_percent_off? && engraving_fee.nonzero?

    [engraving_fee, (engraving_fee * (plan.engraving_percent_off.to_f / 100)).round_at(2)].min
  end

  def membership_shipping_discount(plan = nil)
    if plan.present?
      shipments.map { |s| s.potential_membership_shipping_savings(plan).to_f }.sum(0).round_at(2)
    else
      shipments.map { |s| s.shipment_amount&.membership_shipping_discount.to_f }.sum(0).round_at(2)
    end
  end

  def membership_on_demand_discount(plan = nil)
    if plan.present?
      shipments.map { |s| s.potential_membership_on_demand_savings(plan).to_f }.sum(0).to_f.round_at(2)
    else
      shipments.map { |s| s.shipment_amount&.membership_delivery_discount.to_f }.sum(0).to_f.round_at(2)
    end
  end

  # Colorado charges a delivery fee on any goods delivered through motor vehicles
  def retail_delivery_fee
    shipments.sum(&:retail_delivery_fee).to_f.round_at(2)
  end

  def service_fee_eligible_for_discount?
    @order.all_gift_card_coupons.present?
  end

  def remaining_coupon_value_before_engraving_fee
    remaining_balance = order_total_coupon_available - order_coupon_value
    return 0.0 unless remaining_balance.positive?

    remaining_balance
  end

  def remaining_coupon_value_after_engraving_fee
    remaining_balance = order_total_coupon_available - order_coupon_value
    remaining_balance -= engraving_fee
    return 0.0 unless remaining_balance.positive?

    remaining_balance
  end

  def service_fee_discounts
    return service_fee if membership_plan&.no_service_fee?
    return 0.0 unless service_fee_eligible_for_discount?

    remaining_balance = remaining_coupon_value_after_engraving_fee
    [remaining_balance, service_fee].min
  end

  def service_fee_after_discounts
    (service_fee - service_fee_discounts).round(2)
  end

  def order_total_coupon_available
    return @order_total_coupon_available if defined?(@order_total_coupon_available)

    @order_total_coupon_available = @order.all_coupons.reject(&:membership_coupon?).sum { |item| item.value(@order) }
  end

  def membership_coupon_discount
    return @membership_coupon_discount if defined?(@membership_coupon_discount)

    @membership_coupon_discount =
      [@order.all_coupons.select(&:membership_coupon?).sum { |item| item.value(@order) }, membership_price].min
  end

  def order_coupon_value
    [order_total_coupon_available, total_before_coupon_applied].min
  end

  def free_product_discount
    return 0.0 unless @order.all_coupons.any? { |c| c.free_product_id.present? }

    @order.shipments.sum(&:free_product_discount)
  end

  def coupon_amount
    return @coupon_amount if defined?(@coupon_amount)

    coupon_amount = order_coupon_value
    # coupons = @order.all_gift_card_coupons

    # Discount engraving fee using coupon
    coupon_amount += engraving_fee_discounts_without_membership_discount

    # Discount service fee using coupon
    service_fee_coupon_can_be_applied =
      coupon_amount >= (total_before_coupon_applied + engraving_fee) && service_fee_eligible_for_discount?
    coupon_amount += service_fee_discounts if service_fee_coupon_can_be_applied && !membership_plan&.no_service_fee?

    coupon_amount += free_product_discount
    coupon_amount += membership_coupon_discount
    @coupon_amount = coupon_amount.round(2)
  end

  def coupon_amount_share
    [
      coupon_amount,
      membership_plan&.no_service_fee? ? 0 : service_fee_discounts,
      free_product_discount,
      engraving_fee_discounts_without_membership_discount,
      membership_coupon_discount
    ].reduce(:-)
  end

  def gift_card_amount
    value = coupon_amount
    value -= @order.coupon.value(@order) if @order.coupon&.promo_coupon?
    [value, 0.0].max
  end

  def gift_card_amount_share
    [
      gift_card_amount.to_f,
      membership_plan&.no_service_fee? ? 0 : service_fee_discounts,
      free_product_discount,
      engraving_fee_discounts_without_membership_discount,
      membership_coupon_discount
    ].reduce(:-)
  end

  def total_before_discounts
    sub_total + shipping_charges + tip_amount + taxed_amount + service_fee + video_gift_fee + engraving_fee + retail_delivery_fee + membership_price
  end

  def total_before_coupon_applied
    (total_before_discounts - deals_total - service_fee - video_gift_fee - engraving_fee).to_f.round_at(2)
  end

  def taxed_total
    zero_or_greater(total_before_discounts - discounts_total)
  end

  def current_charge_total
    standard_shipments = shipments.select(&:customer_placement_standard?)

    fees = service_fee + video_gift_fee
    due_today = standard_shipments.sum { |s| s.total_before_discounts + s.engraving_fee_without_discounts }
    due_today += fees if standard_shipments.any?
    due_today += membership_price + membership_tax

    discounts_due_today = discounts_total - shipments.reject(&:customer_placement_standard?).sum(&:discounts_total)

    zero_or_greater(due_today - discounts_due_today)
  end

  def deferred_charge_total
    (total_before_discounts - discounts_total - current_charge_total).to_f.round_at(2)
  end

  def outstanding(order_amount = self)
    standard_shipments, other_shipments = shipments.partition(&:customer_placement_standard?)
    fees =
      if standard_shipments.blank? && @order.order_charges.present?
        order_amount.service_fee + order_amount.video_gift_fee
      else
        0
      end
    paid_other_shipments =
      other_shipments
      .reject { |shipment| shipment.pending? || shipment.test? || shipment.canceled? }
      .sum { |s| s.total_before_discounts + s.engraving_fee_without_discounts - s.discounts_total }
    order_amount.deferred_charge_total - paid_other_shipments - fees
  end

  def to_attributes
    attributes = Hash.new { |hash, attribute| hash[attribute] = public_send(attribute) }
    attribute_methods.each { |attribute| attributes[attribute] }
    attributes
  end

  private

  def shipments
    @order.shipments.load_target.reject(&:canceled?)
  end

  def attribute_methods
    %w[
      shipping_charges
      delivery_fee_discounts_total
      shipping_fee_discounts_total
      shipping_tax
      order_items_total
      order_items_tax
      bottle_deposits
      tip_amount
      sub_total
      taxed_amount
      taxed_total
      additional_tax
      engraving_fee
      engraving_fee_discounts
      engraving_fee_after_discounts
      shipping_after_discounts
      delivery_after_discounts
      deals_total
      coupon_amount
      gift_card_amount
      discounts_total
      total_before_discounts
      total_before_coupon_applied
      shoprunner_total
      service_fee
      bag_fee
      service_fee_discounts
      video_gift_fee
      current_charge_total
      deferred_charge_total
      retail_delivery_fee
      membership_discount
      membership_price
      membership_tax
      membership_service_fee_discount
      membership_engraving_fee_discount
      membership_shipping_discount
      membership_on_demand_discount
      fulfillment_fee
    ]
  end

  def zero_or_greater(amount)
    amount.negative? ? 0.0 : amount.to_f.round_at(2)
  end
end
