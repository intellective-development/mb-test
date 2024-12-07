# frozen_string_literal: true

# This service is used to calculate shipping fee for a given cart
class CartShippingFeeService
  attr_reader :shipping_fee, :shipping_discount, :on_demand_fee, :on_demand_discount,
              :membership_shipping_discount, :membership_on_demand_discount

  def initialize(cart, address)
    @cart = cart
    @address = address
    @storefront = @cart.storefront
    @sub_total = items_sub_total
    @first_on_demand = nil
    @first_shipped = nil

    cart_fees = group_items_by_shipping_method(@cart.cart_items) if @cart.cart_items.count.positive?
    cart_fees ||= {}

    @shipping_fee = cart_fees[:shipping_fee] || 0.0
    @shipping_discount = cart_fees[:shipping_discount] || 0.0
    @on_demand_fee = cart_fees[:on_demand_fee] || 0.0
    @on_demand_discount = cart_fees[:on_demand_discount] || 0.0
    @membership_shipping_discount = cart_fees[:membership_shipping_discount] || 0.0
    @membership_on_demand_discount = cart_fees[:membership_on_demand_discount] || 0.0
  end

  private

  def items_sub_total
    @cart.cart_items.map { |item| item.variant.price * item.quantity }.sum
  end

  def group_items_by_shipping_method(cart_items)
    items_by_shipping_method = {}
    cart_items.each do |cart_item|
      supplier = cart_item.variant.supplier
      shipping_method = supplier_shipping_method(supplier)
      @first_on_demand ||= shipping_method.id if shipping_method.on_demand?
      @first_shipped ||= shipping_method.id if shipping_method.shipped?
      items_by_shipping_method[shipping_method.id] ||= []
      items_by_shipping_method[shipping_method.id] << cart_item
    end

    cart_fees = {
      shipping_fee: 0.0,
      shipping_discount: 0.0,
      on_demand_fee: 0.0,
      on_demand_discount: 0.0,
      membership_on_demand_discount: 0.0,
      membership_shipping_discount: 0.0
    }

    items_by_shipping_method.each do |shipping_method_id, shipping_method_cart_items|
      shipping_method = ShippingMethod.find(shipping_method_id)
      supplier = shipping_method.supplier
      fees = calculate_fee_and_reimbursement!(shipping_method, shipping_method_cart_items, supplier)

      cart_fees[:shipping_fee] += fees[:shipping_fee]
      cart_fees[:shipping_discount] += fees[:shipping_discount]
      cart_fees[:on_demand_fee] += fees[:on_demand_fee]
      cart_fees[:on_demand_discount] += fees[:on_demand_discount]
      cart_fees[:membership_shipping_discount] += fees[:membership_shipping_discount]
      cart_fees[:membership_on_demand_discount] += fees[:membership_on_demand_discount]
    end

    cart_fees.transform_values { |v| v.round_at(2) }
  end

  def calculate_fee_and_reimbursement!(shipping_method, cart_items, supplier)
    fees = {
      shipping_fee: 0.0,
      shipping_discount: 0.0,
      on_demand_fee: 0.0,
      on_demand_discount: 0.0,
      membership_on_demand_discount: 0.0,
      membership_shipping_discount: 0.0
    }
    if @storefront.enable_dynamic_shipping?
      if shipping_method.shipped?
        fees[:shipping_fee] = calculate_dynamic_fee(cart_items, supplier)
      else
        fees[:on_demand_fee] = calculate_fee_for_mode_all(shipping_method, cart_items)
      end
    elsif @storefront.supplier_fee_mode_first?
      fees = calculate_fee_for_mode_first(fees, shipping_method, cart_items)
    elsif @storefront.supplier_fee_mode_all?
      fee = calculate_fee_for_mode_all(shipping_method, cart_items)
      if shipping_method.shipped?
        fees[:shipping_fee] = fee
      else
        fees[:on_demand_fee] = fee
      end
    else
      # Should never happen
      raise "Unexpected supplier_fee_mode: #{@storefront.supplier_fee_mode}"
    end

    apply_membership_discount!(shipping_method, fees)
  end

  def supplier_shipping_method(supplier)
    @shipping_method = supplier.default_shipping_method
    return @shipping_method if @address.blank?
    return @shipping_method if @shipping_method&.covers_address?(@address)

    @shipping_method = supplier.shipping_methods.find { |sm| sm.covers_address?(@address) } || @shipping_method
  end

  def calculate_fee_for_mode_first(fees, shipping_method, cart_items)
    if shipping_method.shipped?
      fee = @storefront.single_shipping_fee
      if @first_shipped == shipping_method.id
        fees[:shipping_fee] = fee
      else
        fees[:shipping_discount] = fee
      end
    else
      fee = calculate_fee_for_mode_all(shipping_method, cart_items)
      if @first_on_demand == shipping_method.id
        fees[:on_demand_fee] = fee
      else
        fees[:on_demand_discount] = fee
      end
    end
    fees
  end

  def calculate_fee_for_mode_all(shipping_method, cart_items)
    return 0 if always_free_delivery?(shipping_method) || (!never_free_delivery?(shipping_method) && !below_free_threshold?(shipping_method))

    incremental = shipping_method.shipped? && !shipping_method&.shipping_flat_fee
    incremental ? incremental_shipping_fee(shipping_method, cart_items) : shipping_method&.delivery_fee.to_f
  end

  def always_free_delivery?(shipping_method)
    minimum = shipping_method&.delivery_minimum
    free_threshold = shipping_method&.delivery_threshold
    fee = shipping_method&.delivery_fee.to_f
    fee.zero? || (free_threshold.present? && free_threshold <= minimum)
  end

  def never_free_delivery?(shipping_method)
    free_threshold = shipping_method&.delivery_threshold
    fee = shipping_method&.delivery_fee.to_f
    free_threshold.blank? && !fee.zero?
  end

  def below_free_threshold?(shipping_method)
    @sub_total < shipping_method&.delivery_threshold
  end

  def incremental_shipping_fee(shipping_method, cart_items)
    shipping_items = cart_items.map(&:quantity).sum
    fee = shipping_method&.delivery_fee.to_f
    extra_qty = shipping_items - 1
    fee += (extra_qty / 12).floor * 30
    fee += (extra_qty % 12) != 0 ? 10 : 0
    fee.to_f.round_at(2)
  end

  def calculate_dynamic_fee(cart_items, supplier)
    CartDynamicShippingService.new(cart_items, supplier, @address).shipping_fee || 0.0
  end

  def apply_membership_discount!(shipping_method, fees)
    if membership_on_demand_discount?(shipping_method)
      fees[:membership_on_demand_discount] += fees[:on_demand_fee]
      fees[:on_demand_discount] = [fees[:on_demand_fee], fees[:on_demand_discount]].max
      fees[:on_demand_fee] -= fees[:on_demand_fee]
    elsif membership_shipping_discount?(shipping_method)
      fees[:membership_shipping_discount] += fees[:shipping_fee]
      fees[:shipping_discount] = [fees[:shipping_fee], fees[:shipping_discount]].max
      fees[:shipping_fee] -= fees[:shipping_fee]
    end
    fees
  end

  def membership_shipping_discount?(shipping_method)
    shipping_method.shipped? && membership_plan&.free_shipping?(@sub_total)
  end

  def membership_on_demand_discount?(shipping_method)
    shipping_method.on_demand? && membership_plan&.free_on_demand?(@sub_total)
  end

  def membership_plan
    @membership_plan ||= Membership.active.find_by(user_id: @cart.user_id, storefront_id: @cart.storefront_id)&.membership_plan
  end
end
