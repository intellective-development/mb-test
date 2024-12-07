# frozen_string_literal: true
#
# This service handles the logic around creating, updating, and validating orders
# coming in from the new checkout endpoint (proxied checkout).

class OrderCreationServicesV2
  attr_reader :order, :error, :amounts

  DEFAULT_OPTIONS = {
    skip_in_stock_check: false,
    skip_scheduling_check: false,
  }.freeze

  REMOVE_PROMO_CODE = 'REMOVE_PROMO_CODE'.freeze

  def initialize(order, user, params, options = {})
    @order = order
    @user = user
    @params = params
    @error = nil
    @options = DEFAULT_OPTIONS.merge(options)
    @order_items = params[:order_items]
  end

  def valid?
    @error.nil?
  end

  def error_args
    [@error.detail, @error.status] if @error.present?
  end

  def build_order
    amounts_calculable = false
    assign_order_attributes
    check_shipping_address
    check_payment_profile

    @order.assign_attributes(order_association_keys)
    build_shipments if @order_items.any?

    if @params[:amounts].present?
      order_amount_params = build_order_amount_params
      @order.order_amount ||= OrderAmount.new(order: @order)
      @order.order_amount.assign_attributes(order_amount_params)
      @order.save_order_amount(skip_coupon_creation: true)
    end

    amounts_calculable = true

    add_membership_id!
    validate_tip_amount

    true
  rescue OrderError => e
    handle_order_error(e, amounts_calculable)
  end

  private

  def build_order_amount_params
    amounts = @params[:amounts] || {}
    LiquidCommerceCoupons::AmountCalculator.calculate_core_amounts(
      amounts,
      amounts[:details],
      @order
    )
  end

  def calculate_shipping_charges(shipping, delivery)
    (shipping + delivery).to_f / 100
  end

  def calculate_shipping_tax(details)
    (details[:shipping] + details[:delivery] + details[:retailDelivery]).to_f / 100
  end

  def handle_order_error(exception, amounts_calculable)
    @error = exception
    @error.amounts = calculate_amounts if amounts_calculable
    @error.number = @order.number if @order
    false
  end

  def assign_order_attributes
    customer = @params[:customer] || {}
    amounts = @params[:amounts] || {}

    @order.assign_attributes(
      email: customer[:email],
      birthdate: customer[:birthDate],
      tip_amount: (amounts[:tip].to_f / 100),
      allow_substitution: @params[:hasSubstitutionPolicy],
      delivery_notes: @params[:deliveryNotes],
      button_referrer_token: @params[:buttonReferrerToken],
      shoprunner_token: @params[:shoprunnerToken],
      storefront_cart_id: @params[:storefrontCartId]
    )
  end

  def check_shipping_address
    if @params[:shippingAddressId]
      validate_shipping_address
    else
      @shipping_address = @order.ship_address
    end

    raise OrderError.new('Given Shipping Address is not allowed', name: 'InvalidShippingAddress') if @shipping_address&.blacklisted_by_block?
  end

  def validate_shipping_address
    @shipping_address = @user.shipping_addresses.active.find_by(id: @params[:shippingAddressId])
    raise OrderError.new('Invalid Shipping Address ID', name: 'InvalidShippingAddress') if @shipping_address.nil?
  end

  def check_payment_profile
    if @params[:paymentProfileId]
      validate_payment_profile
    else
      @payment_profile = @order.payment_profile
    end
  end

  def validate_payment_profile
    @payment_profile = @user.payment_profiles.active.find_by(id: @params[:paymentProfileId])
    raise OrderError.new('Invalid Payment Profile ID', name: 'InvalidPayment') if @payment_profile.nil?
  end

  def order_association_keys
    {
      ship_address: @shipping_address,
      payment_profile: @payment_profile,
      bill_address: @payment_profile&.address
    }
  end

  def build_shipments
    UpdateShipmentsServiceV2.new(@order, @order_items, @params[:retailers], @params[:liquidcommerce_identifiers], **@options).process
  end

  def add_membership_id!
    @order.assign_attributes(
      membership_id: Membership.active.find_by(user_id: @order.user_id, storefront_id: @order.storefront_id)&.id
    )
  end

  def validate_tip_amount
    # Implement any necessary tip amount validations here
  end

  def calculate_amounts
    # Return amounts from the order's amounts
    order_amount = @order.amounts

    # s_tax_fee = @params[:amounts][:details][:taxes][:shipping]
    # d_tax_fee = @params[:amounts][:details][:taxes][:delivery]
    # r_tax_fee = @params[:amounts][:details][:taxes][:retailDelivery]
    #
    # accumulated_ship_delivery_tax = (s_tax_fee + d_tax_fee + r_tax_fee).to_f / 100

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

  class OrderError < StandardError
    extend Forwardable

    attr_reader :status, :detail

    def_delegators :@detail, :[]

    # options: name, status
    def initialize(message, options = {}, extra = nil)
      @status = options.delete(:status) || 500
      @detail = options
      @detail[:message] = message
      @detail[:name] ||= 'OrderError'
      @detail[:extra] = extra unless extra.nil?
      super(message)
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

