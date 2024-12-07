# frozen_string_literal: true

class EligibilityError < StandardError; end

class Coupons::CouponEligibilityService
  attr_accessor :coupon
  attr_reader :order

  def initialize(order)
    @order = order
  end

  def eligible?(coupon)
    @coupon = coupon

    check_expiration_date
    check_minimum_unit
    check_minimum_amount
    check_domain
    check_presale
    check_coupon_items
    check_nth
    check_delivery_fee
    check_shipping_fee
    check_number_of_orders_from_same_user
    check_single_use
    check_platform
    check_supplier_type
    check_membership_plan
    check_free_product
    check_quota

    [true, nil]
  rescue EligibilityError => e
    [false, e.message]
  end

  private

  def check_presale
    raise EligibilityError, error_str(:pre_sale_with_coupon_name) if coupon.exclude_pre_sale? && order.only_pre_sale_items?
  end

  def check_coupon_items
    return if coupon.all?
    return if coupon.coupon_items.none?

    raise EligibilityError, message_for_items if coupon.coupon_items.none? { |ci| ci.matches_restriction_rules?(order) }
  end

  def message_for_items
    items = coupon.coupon_items.map { _1.item.try(:name) }.compact.sort.join(', ')
    message =
      case coupon.coupon_items.first.item
      when ProductType
        :apply_only_to_product_types
      when Supplier
        :apply_only_to_suppliers
      when Brand
        :apply_only_to_brands
      when Product
        :apply_only_to_products
      else
        :generic
      end

    error_str(message, items: items)
  end

  def check_expiration_date
    raise EligibilityError, error_str(:generic) unless coupon.started?(order.completed_at)

    raise EligibilityError, error_str(:expired, expires_at: coupon.expires_at.strftime('%m/%d/%Y')) if coupon.expired?(order.completed_at)
  end

  def check_minimum_unit
    return if coupon.minimum_units.nil?

    raise EligibilityError, error_str(:minimum_required) if order.order_items_count < coupon.minimum_units
  end

  def check_minimum_amount
    return if coupon.minimum_value.nil? || coupon.minimum_value.zero?

    # TODO: refactor minimum_value_exceeded
    raise EligibilityError, error_str(:minimum_required) unless coupon.minimum_value_exceeded?(order)
  end

  def check_nth
    return if coupon.nth_order_item.nil? || coupon.nth_order_item.zero?

    raise EligibilityError, error_str(:minimum_required) if order.order_items.count < coupon.nth_order_item
  end

  def check_delivery_fee
    raise EligibilityError, error_str(:apply_only_delivery_fee) if coupon.free_delivery? && !coupon.free_shipping? && order.shipments.on_demand.empty?
  end

  def check_shipping_fee
    raise EligibilityError, error_str(:apply_only_shipping_fee) if coupon.free_shipping? && !coupon.free_delivery? && order.shipments.shipped.empty?
  end

  def check_number_of_orders_from_same_user
    return if coupon.nth_order.nil?

    user_order_count = order.user.orders.finished.count + 1
    target = coupon.nth_order
    raise EligibilityError, error_str(:apply_only_nth_order, ordinalize: target.ordinalize) unless user_order_count == target
  end

  def check_quota
    raise EligibilityError, error_str(:reached_quota) if coupon.quota_filled?
  end

  def check_single_use
    return unless coupon.single_use?

    times_used = coupon.orders.where(user: order.user).count
    raise EligibilityError, error_str(:user_already_redeemed) if times_used.positive?
  end

  def check_domain
    return if coupon.domain_name.nil?

    raise EligibilityError, error_str(:generic) unless coupon.domain_eligible?(order.user.account.email)
  end

  def check_platform
    return if coupon.doorkeeper_application_ids.nil? || coupon.doorkeeper_application_ids.empty?

    raise EligibilityError, error_str(:generic) unless coupon.platform_eligible?(order)
  end

  def check_supplier_type
    return if coupon.supplier_type.blank?

    none_supplier = order.suppliers.none? { |s| s.dashboard_type == coupon.supplier_type }
    raise EligibilityError, error_str(:generic) if none_supplier
  end

  def check_membership_plan
    raise EligibilityError, error_str(:generic) unless coupon.qualified_membership_plan?(order)
  end

  def check_free_product
    return if coupon.free_product_id.nil?

    raise EligibilityError, error_str(:generic) unless coupon.contains_free_product_in_required_quantity?(order)
  end

  def error_str(key, params = {})
    I18n.t(key, { scope: 'coupons.errors', promo_code: coupon.code }.merge(params))
  end
end
