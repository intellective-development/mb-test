# This service handles the logic around creating, updating, and validating orders
# coming in from the consumer api.

class OrderCreationServices
  attr_reader :order, :error, :amounts

  DEFAULT_OPTIONS = {
    skip_in_stock_check: false,
    override_amounts: false
  }.freeze

  REMOVE_PROMO_CODE = 'REMOVE_PROMO_CODE'.freeze

  def initialize(order, user, cart, params, options = {})
    @order = order
    @user = user
    @cart = cart
    @params = params
    @error = nil
    @options = DEFAULT_OPTIONS.merge(options)
    @order_items = []
  end

  def valid?
    @error.nil?
  end

  def error_args
    [@error.detail, @error.status] if @error.present?
  end

  def build_order
    amounts_calculable = false
    set_order_items_or_error

    @order.assign_attributes(email: @params[:email]) if @params[:email].present?
    @order.assign_attributes(birthdate: @params[:birthdate]) if @params[:birthdate].present?
    @order.assign_attributes(delivery_notes: @params[:delivery_notes]) if @params[:delivery_notes].present?
    @order.assign_attributes(button_referrer_token: @params[:button_referrer_token]) if @params[:button_referrer_token].present?
    @order.assign_attributes(shoprunner_token: @params[:shoprunner_token]) if @params[:shoprunner_token].present?
    @order.assign_attributes(tip_amount: @params[:tip]) if @params[:tip].present?
    @order.assign_attributes(allow_substitution: @params[:allow_substitution]) if @params[:allow_substitution].present?
    @order.assign_attributes(storefront_cart_id: @params[:storefront_cart_id]) if @params[:storefront_cart_id].present?

    check_shipping_address
    check_delivery_notes
    check_payment_profile
    check_pickup_detail

    @order.assign_attributes(order_association_keys)
    build_shipments if @order_items.any?
    amounts_calculable = true
    unset_video_gift_message if @params[:has_video_gift_message] == false
    unset_gift_options if @params[:is_gift] == false
    set_gift_options if @params[:gift_options]
    set_gift_detail if @params[:gift_detail_id]
    set_visit_id if @params[:visit_id]
    set_video_gift_message if @params[:has_video_gift_message] == true

    add_membership_id!

    validate_tip_amount
    validate_promo_code
    validate_coupons

    validate_gift_cards unless @params[:promo_code]&.downcase == REMOVE_PROMO_CODE.downcase
    validate_external_availability

    update_quantity_items_per_order

    true
  rescue OrderError => e
    @error = e
    @error.amounts = calculate_amounts if amounts_calculable
    @error.number = @order.number if @order
    false
  end

  private

  def update_quantity_items_per_order
    LimitedProductOrder.update_purchased_items(@order, @order_items)
  end

  def check_shipping_address
    if @params[:shipping_address_id]
      validate_shipping_address
    else
      @shipping_address = @params.key?(:shipping_address_id) ? nil : @order.ship_address
    end

    raise OrderError.new('Given Shipping Address is not allowed', name: 'InvalidShippingAddress') if @shipping_address&.blacklisted_by_block?
  end

  def check_delivery_notes
    validate_delivery_notes if @params[:delivery_notes]
  end

  def check_pickup_detail
    if @params[:pickup_detail_id]
      validate_pickup_detail
    else
      @pickup_detail = @order.pickup_detail
    end
  end

  def check_payment_profile
    if @params[:payment_profile_id]
      validate_payment_profile
    elsif @params[:payment_profile]
      create_payment_profile
    else
      @payment_profile = @order.payment_profile
    end
  end

  # Validators
  def set_cart_or_error
    if @params[:cart_id].present? || @cart.present?
      @cart ||= Cart.find_by(id: @params[:cart_id], user_id: @user&.id)
      raise OrderError.new('Unauthorized', name: 'InvalidCart') unless @cart
    end
  end

  def set_order_items_or_error
    if @params[:cart_id]
      set_cart_or_error
      set_items_from_cart
    elsif @params[:order_items]
      @order_items = @params[:order_items].map do |item|
        variant = Variant.find_by(id: item[:variant_id])
        item = item.merge(
          {
            id: item[:id] || item[:variant_id],
            identifier: item[:id] || item[:identifier],
            bottle_deposits: item[:bottle_deposits]
          }
        )
        item[:price] = if @options[:override_amounts]
                         item[:price]
                       else
                         storefront_specific_price(variant)
                       end

        item[:total] = ((item[:price].to_f || 0) * (item[:quantity].to_i || 0)).round(2)

        item
      end
    end

    raise OrderError.new('Order items are missing', name: 'InvalidItem', status: 400) if @order_items.none? && @order.order_items.none?
  end

  def storefront_specific_price(variant)
    return nil unless variant

    BusinessVariantPriceService.new(
      variant.price,
      variant.real_price,
      variant.supplier.id,
      @order.storefront&.business,
      variant
    ).call
  end

  def set_items_from_cart
    @order_items = @cart.cart_items.active.active_suppliers.with_views.distinct_items.map do |cart_item|
      {
        id: cart_item.variant_id,
        identifier: cart_item.identifier,
        quantity: cart_item.quantity,
        product_bundle_id: cart_item.product_bundle_id,
        price: cart_item.storefront_specific_price,
        customer_placement: cart_item.customer_placement
      }.merge(order_options(cart_item))
    end
  end

  def order_options(cart_item)
    options = cart_item.item_options&.attributes&.except('id')&.with_indifferent_access
    return {} unless options.present?

    { options: options }
  end

  def validate_pickup_detail
    @pickup_detail = @user.pickup_details.find_by(id: @params[:pickup_detail_id])
    raise OrderError.new('Invalid Pickup Details ID', name: 'InvalidPickupDetails') if @pickup_detail.nil?
  end

  def validate_shipping_address
    @shipping_address = @user.shipping_addresses.active.find_by(id: @params[:shipping_address_id])
    raise OrderError.new('Invalid Shipping Address ID', name: 'InvalidShippingAddress') if @shipping_address.nil?
  end

  def validate_delivery_notes
    raise OrderError.new('Delivery Notes can be max 255 characters long', name: 'InvalidDeliveryNotes') if @params[:delivery_notes].length > 255
  end

  def validate_payment_profile
    @payment_profile = @user.payment_profiles.active.find_by(id: @params[:payment_profile_id])
    raise OrderError.new('Invalid Payment Profile ID', name: 'InvalidPayment') if @payment_profile.nil?
  end

  def create_payment_profile
    address_params = @params[:payment_profile][:address].merge(
      address_purpose: nil,
      billing_default: false
    )
    address = AddressCreationService.new(@user, @order.doorkeeper_application).create(address_params)
    raise OrderError.new('Invalid Billing Address', name: 'InvalidBillingAddress') unless address

    payment_method_params = {
      payment_method_nonce: @params[:payment_profile][:payment_method_nonce],
      reusable: false,
      storefront: @params[:storefront],
      ip_address: @params[:ip_address]
    }
    payment_profile = PaymentMethodCreationService.new(@user, @order.doorkeeper_application).create(payment_method_params, address)
    raise OrderError.new('Invalid Payment Profile', name: 'InvalidPayment') unless payment_profile

    @payment_profile = payment_profile
  end

  def get_non_alcoholic_discount_message
    promo_code = @params[:promo_code].downcase.squish
    state_abbreviation = @order&.ship_address&.state&.abbreviation || @order&.ship_address&.state_name || @order&.promo_address&.fetch('state')
    state = State.find_by(abbreviation: state_abbreviation)
    state_name = @order&.ship_address&.state&.name || state&.name || state_abbreviation

    message = "In #{state_name}, '#{String(promo_code).upcase}' is valid on non-alcoholic items only." if state_abbreviation == 'MO'
    message ||= "In #{state_name}, '#{String(promo_code).upcase}' is valid on delivery fees and non-alcoholic items only."
    message
  end

  def raise_coupon_error(coupon, promo_code)
    raise OrderError.new("The code '#{String(promo_code).upcase}' cannot be applied on gift card orders.", name: 'InvalidPromoCode') if @order.digital?

    if coupon.present?
      raise OrderError.new("The code '#{String(promo_code).upcase}' is invalid. In Missouri, promo codes are valid on non-alcoholic items only", name: 'InvalidPromoCode') unless coupon.shipping_discount_eligible?(order)
      raise OrderError.new(get_non_alcoholic_discount_message, name: 'InvalidPromoCode') if coupon.get_errors(order).any? { |err| err == coupon.error_str(:disallow_alcohol) }
      raise OrderError.new(coupon.error_str(:pre_sale_with_coupon_name, promo_code: promo_code), name: 'InvalidPromoCode') if coupon.get_errors(order).any? { |err| err == coupon.error_str(:pre_sale) }
      raise OrderError.new("The code '#{String(promo_code).upcase}' is invalid. In #{order.ship_address_state}, promo codes are only valid on delivery fees and non-alcoholic items", name: 'InvalidPromoCode') unless coupon.shipping_alcohol_discounts?(order)
      if !coupon.eligible?(@order) && !coupon.eligible_for_first_purchase?(@order)
        raise OrderError.new("The code '#{String(promo_code).upcase}' is valid on your first purchase only", name: 'InvalidPromoCode')
      elsif !coupon.qualified_order?(@order.user)
        nth_order_string = coupon.nth_order.to_i.ordinalize
        raise OrderError.new("The code '#{String(promo_code).upcase}' is valid on your #{nth_order_string} purchase only", name: 'InvalidPromoCode')
      elsif !coupon.qualified_suppliers?(@order)
        raise OrderError.new("The code '#{String(promo_code).upcase}' is valid on #{coupon.supplier_type.titleize} order only", name: 'InvalidPromoCode')
      elsif !coupon.qualified_membership_plan?(@order)
        raise OrderError.new("The code '#{String(promo_code).upcase}' is only for members", name: 'InvalidPromoCode')
      end
    end
    raise OrderError.new("The code '#{String(promo_code).upcase}' is invalid", name: 'InvalidPromoCode')
  end

  ##
  # Add a coupon to an order or raise an exception if it cant
  #
  def add_coupon_or_raise(coupon)
    if Feature[:enable_new_coupon_message].enabled?
      eligible, message = Coupons::CouponEligibilityService.new(@order).eligible?(coupon)
      raise OrderError.new(message, name: 'InvalidPromoCode') unless eligible

      @order.add_coupon(coupon)
    else
      raise_coupon_error coupon, coupon.code unless @order.add_coupon(coupon)
    end
  end

  def coupon_from_code(promo_code)
    coupon = Coupon.find_coupon_or_create_if_exists_referrer(promo_code, @order.storefront)

    raise OrderError.new(I18n.t('coupons.errors.generic', promo_code: promo_code.upcase), name: 'InvalidPromoCode') if coupon.nil? || coupon.gift_card_coupon?

    coupon
  end

  def remove_coupons
    @order.coupons = []
  end

  def remove_gift_cards_from_order
    @order.coupons = @order.coupons.coupon_not_decreasing_balance
  end

  def remove_promo_code
    @order.coupon = nil
  end

  ##
  # Adds a promo code to an order
  #
  # This method will add a promo code, if present, to an order. It will also run any validations necessary to
  # make sure the promo code is valid.
  #
  def validate_promo_code
    return if @params[:promo_code].blank?

    if @params[:promo_code].downcase == REMOVE_PROMO_CODE.downcase
      remove_promo_code
      return
    end

    promo_code = @params[:promo_code].downcase.squish
    gift_card_exists = @order.coupons.find { |item| item.code == promo_code }

    raise OrderError.new("The code '#{String(promo_code).upcase}' is already in use", name: 'InvalidGiftCard') unless gift_card_exists.nil?

    add_coupon_or_raise coupon_from_code(promo_code)
  end

  ##
  # Validates multiple coupons per order
  #
  # If a storefront has the multiple coupons enable, this method will validate each one of them.
  #
  def validate_coupons
    return if @params[:coupons].nil?

    # remove all
    # we do this because it is easier than checking what was removed.
    remove_promo_code
    remove_coupons

    return if @params[:coupons].blank?

    gift_cards = []
    @params[:coupons].uniq.map do |coupon_code|
      gift_card = Coupon.find_active_gift_card_by_code(coupon_code.downcase.squish, @order.storefront)
      if gift_card.present?
        validate_gift_card(coupon_code, gift_card)
        gift_cards << gift_card
      else
        coupon = coupon_from_code(coupon_code)

        checking_multiple_promo_coupons

        add_coupon_or_raise coupon
      end
    end

    add_gift_cards_to_order(gift_cards) if gift_cards.present?
  end

  def checking_multiple_promo_coupons
    return if @order.storefront.enable_multiple_coupons?
    return if @order.coupon.blank?

    raise OrderError.new("Storefront doesn't allow multiple coupons", name: 'InvalidMultipleCoupon')
  end

  def validate_gift_card(promo_code, gift_card)
    raise OrderError.new("The code '#{String(promo_code).upcase}' is invalid", name: 'InvalidGiftCard') if gift_card.nil?
    raise OrderError.new('Gift card is not applicable', name: 'InvalidGiftCard') unless gift_card.storefront_id == @order.storefront_id
    raise OrderError.new("The code '#{String(promo_code).upcase}' is already in use", name: 'InvalidGiftCard') if gift_card.code == @order.coupon&.code
    raise OrderError.new("The code '#{String(promo_code).upcase}' is only for members", name: 'InvalidGiftCard') unless gift_card.qualified_membership_plan?(@order)
  end

  def validate_gift_cards
    return if @params[:gift_cards].nil?

    # remove all gift cards from the order but keep other types of coupons
    # we do this because it is easier than checking what was removed.
    remove_gift_cards_from_order
    return if @params[:gift_cards].blank?

    raise OrderError.new('Cannot be applied on gift card orders.', name: 'InvalidPromoCode') if @order.digital?

    gift_cards = @params[:gift_cards].uniq.map do |promo_code|
      Coupon.find_active_gift_card_by_code(promo_code.downcase.squish, @order.storefront).tap do |gift_card|
        validate_gift_card(promo_code, gift_card)
      end
    end

    add_gift_cards_to_order(gift_cards)
  end

  def add_gift_cards_to_order(gift_cards)
    @order.add_gift_cards(gift_cards)
  rescue RuntimeError => e
    raise OrderError.new(e, name: 'InvalidGiftCard')
  end

  def validate_external_availability
    seven_eleven_shipments = @order.shipments.select { |s| s&.supplier&.dashboard_type == Supplier::DashboardType::SEVEN_ELEVEN }
    seven_eleven_shipments.each do |shipment|
      ds = Dashboard::Integration::SevenEleven::DataService.new(shipment) # raises Dashboard::Integration::Error::PublicError

      next unless Feature[:seven_eleven_bag_fee].enabled?

      shipment.override_bag_fee(ds.get_bag_fee)
      shipment.order_items.each do |oi|
        oi.bottle_deposits = ds.get_bottle_fee_from_item(oi.variant.sku)
        oi.save
      end
      shipment.save_shipment_amount
    end
  end

  def set_video_gift_message
    fee = @order.storefront&.business&.video_gift_fee
    if fee&.positive?
      @order.save_order_amount(skip_coupon_creation: true)
      @order.order_amount.video_gift_fee = fee
    end
  end

  def unset_video_gift_message
    @order.amounts.video_gift_fee = 0.0
  end

  def set_gift_detail
    @order.gift_detail = GiftDetail.find(@params[:gift_detail_id])
  end

  def unset_gift_options
    @order.gift_detail_id = nil
  end

  def set_gift_options
    @order.gift_detail = GiftDetail.create unless @order.gift_detail
    return unless @order.ship_address || @params[:shipping_address_id]

    @order.gift_detail.message = @params[:gift_options][:message]
    @order.gift_detail.recipient_name = @params[:gift_options][:recipient_name]
    @order.gift_detail.recipient_phone = @params[:gift_options][:recipient_phone]
    @order.gift_detail.recipient_email = @params[:gift_options][:recipient_email]
  end

  def validate_tip_amount
    # for spec's orders we reject tips higher than $120
    has_specs_shipment = @order.shipments.select { |s| s&.supplier&.dashboard_type == Supplier::DashboardType::SPECS }
    unless has_specs_shipment.empty?
      tip_limit_exceeded = @params[:tip].present? && @params[:tip] > 120
      raise OrderError.new('Max allowed tip amount is $120', { name: 'InvalidTip', status: 400 }, { maxTip: 120 }) if tip_limit_exceeded
    end
  end

  def set_visit_id
    @order.visit_id = @params[:visit_id]
  end

  def calculate_amounts
    order_amount = @order.amounts
    amounts = {
      coupon: @order.coupon_amount,
      shipping: @order.shipping_charges,
      tax: order_amount.sales_tax,
      total: @order.taxed_total,
      subtotal: @order.sub_total + order_amount.engraving_fee,
      tax_total: order_amount.total_taxed_amount,
      bottle_deposits: order_amount.bottle_deposits,
      bag_fee: order_amount.bag_fee,
      service_fee: order_amount.service_fee,
      engraving_fee: order_amount.engraving_fee,
      retail_delivery_fee: order_amount.retail_delivery_fee,
      tip_eligible_amount: @order&.tip_eligible_amount,
      delivery_charges: order_amount.delivery_charges,
      video_gift_fee: order_amount.video_gift_fee,
      current_charge_total: order_amount.current_charge_total,
      deferred_charge_total: order_amount.deferred_charge_total,
      shipping_after_discounts: @order.shipping_after_discounts,
      delivery_after_discounts: @order.delivery_after_discounts,
      discounts: {
        coupons: @order.coupon_amount,
        deals: @order.deals_total
      }
    }
    amounts[:tip] = @order.tip_amount unless @order.eligible_total_for_tipping.zero?
    amounts
  end

  def order_association_keys
    {
      ship_address: @shipping_address,
      payment_profile: @payment_profile,
      pickup_detail: @pickup_detail,
      bill_address: @payment_profile&.address
    }
  end

  def build_shipments
    UpdateShipmentsService.new(@order, @order_items, @params[:retailers], **@options).process
  end

  def add_membership_id!
    @order.assign_attributes(
      membership_id: Membership.active.find_by(user_id: @order.user_id, storefront_id: @order.storefront_id)&.id
    )
  end

  class OrderError < ArgumentError
    extend Forwardable

    attr_reader :status, :detail

    def_delegators :@detail, :[]

    # options: name, status
    def initialize(body, options = {}, extra = nil)
      @status = options.delete(:status) || 500
      @detail = options
      @detail[:message] = body
      @detail[:name] ||= 'OrderError'
      @detail[:extra] = extra unless extra.nil?
    end

    def amounts=(amount)
      @detail[:amounts] = amount
    end

    def number=(number)
      @detail[:number] = number
    end

    def to_s
      "#{@detail[:name]}: #{@detail[:number]} - #{@detail[:message]}"
    end
  end
end
