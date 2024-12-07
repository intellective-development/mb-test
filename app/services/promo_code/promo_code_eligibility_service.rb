# frozen_string_literal: true

class EligibilityError < StandardError; end

module PromoCode
  # Class to check if a promo code is eligible for a cart
  class PromoCodeEligibilityService
    attr_accessor :errors

    def initialize(cart, coupon)
      @cart = cart
      @user = cart.user
      @shipping_address = @user.addresses.last
      @coupon = coupon
      @errors = []
    end

    def eligible?
      @errors.append(error_str(:eligible)) unless @coupon.started?(Time.zone.now)
      @errors.append(error_str(:quota, quota: @coupon.quota)) if @coupon.quota_filled?
      @errors.append(error_str(:email_domain)) unless @coupon.domain_eligible?(@user.email)
      @errors.append(error_str(:customer)) unless @coupon.customer_eligible?(@user)
      @errors.append(error_str(:qualified_order, order: @coupon.nth_order.to_i.ordinalize)) unless @coupon.qualified_order?(@user)
      @errors.append(error_str(:qualified_membership_plan)) unless qualified_membership_plan?
      @errors.append(error_str(:supplier_type, supplier: @coupon&.supplier_type&.titleize)) unless qualified_suppliers?(@cart.cart_items)
      @errors.append(error_str(:free_product)) unless contains_free_product_in_required_quantity?(@cart.cart_items)
      @errors.append(error_str(:minimum_units, minimum_units: @coupon.minimum_units)) unless minimum_units_met?(@cart.cart_items)
      @errors.append(error_str(:minimum_value, minimum_value: @coupon.minimum_value.to_f)) unless minimum_value_exceeded?(@cart.cart_items)
      @errors.append(error_str(:qualified_item)) unless qualified_item?(@cart.cart_items)
      @errors.append(error_str(:region)) unless region_eligible?(@cart.cart_items, @shipping_address)
      @errors.append(error_str(:pre_sale)) if @coupon.exclude_pre_sale? && only_pre_sale_items?(@cart.cart_items)
      @errors.append(error_str(:disallow_alcohol)) if disallow_alcohol_discounts?(@shipping_address)
      @errors.append(error_str(:platform_eligible)) unless platform_eligible?(@cart.doorkeeper_application_id)
    end

    private

    def items_quantity(items)
      items.map(&:quantity).inject(:+) || 0
    end

    def in_pre_sale?(item)
      PreSale.active.find_by(product_id: item&.variant&.product_id).present?
    end

    def platform_eligible?(doorkeeper_application_id)
      return true if doorkeeper_application_id.blank?

      @coupon.doorkeeper_application_ids.any? ? @coupon.doorkeeper_application_ids.include?(doorkeeper_application_id.to_i) : true
    end

    def region_eligible?(items, address)
      return true if address&.state_name.blank?

      # In Misourri, orders must contain a mixer.
      disallow_shipping_discounts?(address) ? mixers?(items) : true
    end

    def disallow_alcohol_discounts?(address)
      return false if address&.state_name.blank?

      address.state_name == 'TX'
    end

    def disallow_shipping_discounts?(address)
      return false if address&.state_name.blank?

      address.state_name == 'MO'
    end

    def mixers?(items)
      items.any? { |item| item&.variant&.product&.hierarchy_category_name == 'mixers' }
    end

    def qualified_suppliers?(items)
      return true if items.blank? || @coupon.supplier_type.blank?

      items.all? { |item| item&.supplier&.dashboard_type == @coupon.supplier_type }
    end

    def contains_free_product_in_required_quantity?(items)
      return true if @coupon.free_product_id.blank?

      total = items.map { |item| item&.variant&.product_id == @coupon.free_product_id ? item.quantity : 0 }.inject(:+)
      total <= @coupon.free_product_id_nth_count
    end

    def minimum_units_met?(items)
      return true if @coupon.minimum_units.blank?

      items_quantity(items) >= @coupon.minimum_units
    end

    def minimum_value_exceeded?(items)
      return true if @coupon.minimum_value.blank?

      total = items.map { |item| item.price * item.quantity }.inject(:+)
      total >= @coupon.minimum_value
    end

    def qualified_item?(items)
      @coupon.all? || @coupon.coupon_items.none? || @coupon.coupon_items.any? { |coupon_item| matches_restriction_rules?(coupon_item, items) }
    end

    def matches_restriction_rules?(coupon_item, items)
      items.map do |item|
        return true if check_item(coupon_item, item)
      end

      false
    end

    def check_item(coupon_item, item)
      variant = item.variant
      item_id = coupon_item.item_id
      case coupon_item.item
      when Supplier
        supplier_ids = [item_id] + coupon_item.item.get_child_supplier_ids
        supplier_ids.include?(variant&.supplier_id)
      when Brand
        (variant&.brand&.id == item_id) || (variant&.brand&.parent_brand_id == item_id)
      when Variant
        variant&.id == item_id
      when ProductType
        variant&.product_type&.id == item_id
      when Product
        variant&.product_id == item_id
      end
    end

    def only_pre_sale_items?(items)
      return false if items.empty?

      items.reject { |item| in_pre_sale?(item) }.empty?
    end

    def qualified_membership_plan?
      return true if @coupon.membership_plan_id.nil?
      return false if @user.nil?

      Membership.active.find_by(user_id: @user.id)&.membership_plan_id == @coupon.membership_plan_id
    end

    def error_str(key, params = {})
      I18n.t(key, { scope: 'coupons.errors' }.merge(params))
    end
  end
end
