# frozen_string_literal: true

module Carts
  # Carts::CartAmountService
  #
  # Service that Create the new Cart Amount
  class CartAmountService
    attr_reader :cart, :shipping_address

    def initialize(cart)
      @cart = cart
      @items = cart.cart_items.active
      @shipping_address = cart.address || cart.user.addresses.last
    end

    def call
      CartAmount.new(
        {
          subtotal: subtotal,
          total: total,
          tip: 0
        }.merge(fees)
          .merge(taxes)
          .merge(discounts)
      )
    end

    def fees
      @fees ||= {
        bag_fee: bag_fee,
        service_fee: service_fee,
        engraving_fee: engraving_fee,
        retail_delivery_fee: retail_delivery_fee,
        bottle_deposits_fee: bottle_fee,
        shipping_fee: shipping_fee,
        on_demand_fee: on_demand_fee
      }
    end

    def taxes
      @taxes ||=
        {
          sales_tax: sales_tax,
          shipping_tax: shipping_tax,
          on_demand_tax: on_demand_tax
        }
    end

    def cart_tax_service
      @cart_tax_service ||= CartTaxService.new(cart).call
    end

    def cart_shipping_fee_service
      @cart_shipping_fee_service ||= CartShippingFeeService.new(cart, shipping_address)
    end

    def shipping_tax
      @shipping_tax ||= cart_tax_service[:shipping_tax]
    end

    def on_demand_tax
      @on_demand_tax ||= cart_tax_service[:on_demand_tax]
    end

    def retail_delivery_fee
      @retail_delivery_fee ||= cart_tax_service[:retail_delivery_fee]
    end

    def sales_tax
      @sales_tax ||= cart_tax_service[:total_tax_calculated]
    end

    def bottle_fee
      @bottle_fee ||= cart_tax_service[:bottle_fee]
    end

    def bag_fee
      @bag_fee ||= cart_tax_service[:bag_fee]
    end

    def shipping_fee
      @shipping_fee ||= cart_shipping_fee_service.shipping_fee
    end

    def on_demand_fee
      @on_demand_fee ||= cart_shipping_fee_service.on_demand_fee
    end

    def discounts
      @discounts ||=
        {
          shipping_discount: shipping_discount,
          on_demand_discount: on_demand_discount,
          engraving_discount: engraving_discount,
          service_discount: service_discount,
          sales_discount: coupon_discount,
          gift_card_discount: gift_card_discount
        }
    end

    def subtotal
      @subtotal ||= @items.sum(&:total)
    end

    def total
      @total ||= subtotal + fees.values.sum + taxes.values.sum - discounts.values.sum
    end

    def gift_card_discount
      amount_from_items = @items.filter_map { |cart_item| cart_item.variant.gift_card? ? nil : cart_item.total }.sum
      amount_allowed_for_gc = amount_from_items + taxes.values.sum + fees.values.sum - coupon_discount

      total_balance = cart.gift_cards.sum(&:balance)

      [total_balance, amount_allowed_for_gc].min
    end

    def coupon_discount
      if (coupon = cart.promo_code.presence)
        discount = items_discount(coupon)
        case coupon.type
        when 'CouponValue'
          [discount, coupon.amount].min
        when 'CouponPercent'
          coupon.percent / 100.0 * discount
        else
          0
        end
      else
        0
      end
    end

    def service_fee
      @service_fee ||= cart.storefront.business.service_fee
    end

    def engraving_fee
      engraving_price = cart.storefront.engraving_fee
      qty_engraving = @items.count { |cart_item| cart_item.variant.engraving? && cart_item.item_options.instance_of?(EngravingOptions) }

      @engraving_fee ||= engraving_price * qty_engraving
    end

    def engraving_discount
      percent_discount = cart.promo_code&.engraving_percent || 0

      return 0 if percent_discount.zero?

      # the value is stored as integer 35 for 35%
      @engraving_discount ||= engraving_fee * percent_discount / 100.0
    end

    def service_discount
      return service_fee if cart.promo_code&.free_service_fee?

      0
    end

    def shipping_discount
      return shipping_fee if cart.promo_code&.free_shipping?

      0
    end

    def on_demand_discount
      return on_demand_fee if cart.promo_code&.free_delivery?

      0
    end

    def items_discount(coupon)
      discountable_items(coupon).lazy.map { |item| item.variant.price }.max || 0
    end

    def discountable_items(coupon)
      items = exclude_pre_sale_items(coupon, @items)

      if @shipping_address.state_name == 'TX'
        items.select { |item| item&.variant&.product&.hierarchy_category_name == 'mixers' }
      elsif restrict_items?(coupon)
        items.select { |item| coupon.applicable_variant_ids.include?(item.variant_id) }
      else
        items
      end
    end

    def restrict_items?(coupon)
      coupon.restrict_items? && !coupon.all? || coupon.coupon_items.exists?
    end

    def exclude_pre_sale_items(coupon, items)
      return items unless coupon.exclude_pre_sale

      items.reject { |item| PreSale.active.find_by(product_id: item.variant.product_id).present? }
    end
  end
end
