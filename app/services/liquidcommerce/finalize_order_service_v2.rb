# frozen_string_literal: true

class FinalizeOrderServiceV2
  include SentryNotifiable
  extend ActiveModel::Naming

  def initialize(order, options = {})
    @order = order
    @pending_shipments = @order.shipments.not_paid
    @pre_sale_shipments = []
    @back_order_shipments = []
    @delayed_payment_shipments = []
    @errors = ActiveModel::Errors.new(self)
    @charges = []
    @success = false
    @options = options
  end

  attr_reader :errors, :card, :payment_profile, :charges, :supplier, :options

  #----------------------------------------
  # Class methods
  #----------------------------------------
  def self.human_attribute_name(attr, _options = {})
    attr
  end

  def self.lookup_ancestors
    [self]
  end

  def self.i18n_scope
    'activemodel'
  end

  def self.perform_inline?
    @perform_inline
  end

  # rubocop:disable Style/TrivialAccessors
  def self.perform_inline=(inline)
    @perform_inline = inline
  end

  # rubocop:enable Style/TrivialAccessors

  #----------------------------------------
  # Instance methods
  #----------------------------------------

  def process
    return false unless merchant_accounts_valid?
    return false unless payment_profile_valid?
    return false unless address_covered_by_suppliers?
    return false unless birthdate_valid?

    handle_pre_sale_and_back_orders

    return false if @pending_shipments.empty? && @pre_sale_shipments.empty? && @back_order_shipments.empty?

    # Skip inventory checks if necessary
    # return false unless validate_items_quantity_in_inventory?

    @order.shipments.each do |shipment|
      next if @order.pickup? || shipment.delivery_service.blank? || shipment.shipped?

      begin
        case shipment.delivery_service&.name
        when 'DoorDash'
          DoorDashService.new.create_estimate(shipment.id)
        when 'DeliverySolutions'
          DeliverySolutionsService.new.get_delivery_assurance(shipment.id)
        when 'Zifty'
          ZiftyService.new.create_estimate(shipment.id)
        end

        # metric 0 to give us a % when getting the avg
        MetricsClient::Metric.emit('minibar_web.order.finalize.delivery_service_error', 0)
      rescue DoorDashError, UberError, DeliverySolutionsError, DeliverySolutionsAssuranceError, ZiftyError => e
        errors.add(:supplier, 'Unable to process order. Delivery cannot be completed to the given address.')

        MetricsClient::Metric.emit('minibar_web.order.finalize.delivery_service_error', 1)
        log_delivery_service_error(shipment, e)
        return false
      end
    end

    delay_payments!
    authorize_all_charges or (return false)

    transition_shipments!

    verify_order! if @pending_shipments.present?

    @order.update(finalized_at: Time.current)
    produce_finalize_kafka_message!
    add_delayed_job!
    @success = true
  rescue StandardError => e
    errors.add(:base, "#{e.class.name}: #{e.message}")
    cancel_finalize if @order.finalizing?
    raise e
  end

  def authorize_all_charges
    unless add_membership.success?
      errors.add(:membership, add_membership.error)
      return false
    end

    zero_value_shipments, non_zero_value_shipments = split_shipments_by_zero

    # Supplier Charges - subtotal + shipping fee (no tax) + tip
    authorize_shipment_charges(non_zero_value_shipments) or (return false) if non_zero_value_shipments.any?

    # Minibar Charges
    # sales tax + bottle deposit fee + bag fee + engraving fee + service fee + video gift fee + membership tax
    authorize_minibar_charges(@pending_shipments) or (return false)

    true
  end


  def add_membership
    @add_membership ||= ::Order::AddMembership.new(order: @order).call
  end

  def verify_order!
    Charges::ChargeOrderService.verify_order(@order, @charges)
  end

  def merchant_accounts_valid?
    return true if @order.order_suppliers.all?(&:get_braintree_merchant_account_id)

    errors.add(:supplier, :invalid)
    false
  end

  def payment_profile_valid?
    return true if @order.bulk_order?
    return true if @order.covered_by_discounts? && Feature[:enable_empty_payment_profile].enabled?

    if @order.payment_profile.nil?
      errors.add(:payment_profile, "Payment profile can't be blank")
      Rails.logger.error "Order #{@order.number} trying to be finalized without payment profile"
      return false
    end

    if PaymentProfile::CREDIT_CARD_METHODS.include?(@order.payment_profile.payment_type)
      if @order.payment_profile.payment_type == PaymentProfile::AFFIRM && !@order.affirm_supported?
        errors.add(:payment_type, :invalid)
        return false
      end

      token = @order.payment_profile.braintree_token
      return true if token && PaymentGateway::CreditCard.find_by_token(token, storefront&.business, @order.payment_profile.payment_type)

      errors.add(:card, :invalid)
      false
    else
      true
    end
  end

  def address_covered_by_suppliers?
    return true unless storefront.default_storefront?
    return true unless Feature[:validate_address_on_checkout].enabled?
    return true if @order.ship_address.blank? # digital orders, presence is already validated before this

    not_covered_shipment = @order.shipments.find do |shipment|
      !address_covered_by_shipment_supplier?(shipment)
    end

    if not_covered_shipment
      errors.add(:shipment, "Supplier #{not_covered_shipment.supplier.name} does not deliver to your address.")
      false
    else
      true
    end
  end

  def address_covered_by_shipment_supplier?(shipment)
    return true if %w[pickup digital].include?(shipment.shipping_method.shipping_type)

    shipment.shipping_method.covers_address?(@order.ship_address)
  end

  def birthdate_valid?
    return true if @order.bulk_order?

    if storefront.enable_birthdate_collection
      user = @order.user

      @order.update(birthdate: user.birth_date) if user.birth_date.present? && @order.birthdate.blank?

      if @order.birthdate.blank?
        errors.add(:user, 'User birth date is required')
        return false
      end

      birthdate = Date.parse(@order.birthdate)

      if birthdate.age < 21
        errors.add(:user, 'User must be over 21 years old to use this service')
        return false
      end

      user.update(birth_date: @order.birthdate) if @order.birthdate.present? && user.birth_date.blank?
    elsif storefront.enable_legal_age_collection && !options[:legal_age_agreement] && !options[:skip_legal_age_agreement]
      errors.add(:user, 'Legal age agreement is required.')
      return false
    end

    true
  end

  def authorize_minibar_charges(shipments)
    return true unless shipments.present?

    amount = 0

    # Order Service Fee
    amount += @order.amounts.service_fee_after_discounts

    # Video gift fee
    amount += @order.amounts.video_gift_fee

    # Membership tax
    amount += @order.amounts.membership_tax.to_f

    # Shipments taxes and fees
    shipments.each do |shipment|
      amount += shipment.total_minibar_charge
    end

    return true if amount.to_f.zero?

    create_and_authorize_minibar_charge_inline(amount.to_f.round(2))

    return true if all_charges_authorized?

    cancel_authorized_charges
    errors.add(:card, :declined) if @charges.any?(&:declined?)
    errors.add(:card, :failed) if @charges.any?(&:failed?)
    false
  rescue StandardError => e
    cancel_authorized_charges
    raise e
  end

  def create_and_authorize_minibar_charge_inline(amount)
    @charges << create_and_authorize_minibar_charge(amount)
  end

  def create_and_authorize_minibar_charge(amount)
    supplier_id = storefront.business.fee_supplier.id
    chargeable = @order.order_charges.build(amount: amount, supplier_id: supplier_id, description: 'Taxes and Fees')
    charge = chargeable.build_charge
    chargeable.save!
    charge.authorize!(submit_for_settlement: true)
    charge
  end

  def perform_inline?(shipments)
    shipments.one? || (storefront.non_endemic? && Feature[:non_endemic_perform_inline].enabled?)
  end

  def authorize_shipment_charges(shipments)
    if perform_inline?(shipments) || self.class.perform_inline?
      create_and_authorize_charges_inline(shipments)
    else
      create_and_authorize_charges(shipments)
    end

    return true if all_charges_authorized?

    cancel_authorized_charges
    errors.add(:card, :declined) if @charges.any?(&:declined?)
    errors.add(:card, :failed) if @charges.any?(&:failed?)
    false
  rescue StandardError => e
    cancel_authorized_charges
    raise e
  end

  def transition_shipments!
    @pending_shipments.each(&:pay!)
    @pre_sale_shipments.each do |shipment|
      shipment.set_as_pre_sale! if shipment.pending?
    end
    @back_order_shipments.each do |shipment|
      shipment.set_as_back_order! if shipment.pending?
    end
  end

  def cancel_shipment_transitions_to_paid!
    @pending_shipments.each do |shipment|
      shipment.cancel_payment if shipment.paid?
      shipment.refund! if shipment.charges.present?
    end
    @order.refund_order_charges!
  end

  def cancel_finalize
    cancel_shipment_transitions_to_paid!
    @order.cancel_finalize if @order.finalizing?
  end

  def split_shipments_by_zero
    @pending_shipments.partition { |s| s.total_supplier_charge.to_f.zero? }
  end

  def all_charges_authorized?
    @charges.all?(&:authorized_or_settling?)
  end

  def create_and_authorize_supplier_charge(shipment)
    chargeable = shipment.shipment_charges.build({ amount: shipment.total_supplier_charge })
    charge = chargeable.build_charge
    chargeable.save!
    charge.authorize!(submit_for_settlement: true)
    charge
  end

  def create_and_authorize_charges_inline(shipments)
    shipments.each do |shipment|
      @charges << create_and_authorize_supplier_charge(shipment)
    end
  end

  def create_and_authorize_charges(shipments)
    promises = shipments.map do |shipment|
      Threaded.later { create_and_authorize_supplier_charge_in_promise(shipment) }
    end

    @charges = promises.map(&:value)
  end

  def create_and_authorize_supplier_charge_in_promise(shipment)
    ActiveRecord::Base.connection_pool.with_connection do
      create_and_authorize_supplier_charge(shipment)
    end
    # This is unlikely to ever happen in the real world but
    # let's retry if the pool ever gets maxed out.
  rescue ActiveRecord::ConnectionTimeoutError => e
    notify_sentry_and_log(e,
                          "Charge not created: ConnectionTimeoutError. #{e.message}",
                          { tags: { shipment_id: shipment.id, message: e.message } })

    sleep 2
    retry
  rescue StandardError => e
    notify_sentry_and_log(e,
                          "Charge not created: ConnectionTimeoutError. #{e.message}",
                          { tags: { shipment_id: shipment.id, order_id: @order&.id, backtrace: caller, message: e.message } })
    raise e
  end

  def cancel_authorized_charges
    Memberships::Refund.new(membership: @order.membership).call if @order.membership_plan_id.present? && @order.membership_id.present?
    @charges.each do |charge|
      charge.cancel! if charge&.authorized_or_settling?
    end
  end

  def handle_pre_sale_and_back_orders
    standard_shipments = []
    pre_sale_shipments = []
    back_order_shipments = []
    @pending_shipments.each do |shipment|
      standard_shipments << shipment if shipment.customer_placement_standard?
      pre_sale_shipments << shipment if shipment.customer_placement_pre_sale?
      back_order_shipments << shipment if shipment.customer_placement_back_order?
    end

    @pending_shipments = standard_shipments
    @pre_sale_shipments = pre_sale_shipments
    @back_order_shipments = back_order_shipments
  end

  def read_attribute_for_validation(attr)
    send(attr)
  end

  def success?
    @success
  end

  private

  def log_delivery_service_error(shipment, error)
    supplier = shipment.supplier
    delivery_service = shipment.delivery_service&.name
    notify_sentry_and_log(error,
                          "Order cannot be finalized, estimation failed. Supplier: #{supplier&.name}. Delivery service: #{delivery_service}. #{error.message}",
                          { tags: { order_id: @order.id } })
  end

  # If order_item is:
  #   1) back_order: allow any quantity
  #   2) pre_sale: if order_item.qty is greater than max_remaining_qty, throw an error
  #   3) standard: if order_item is standard and quantity is <= 0, throw an error stating
  def validate_items_quantity_in_inventory?
    return true unless Feature[:prevent_order_finalization_with_inventory_quantity_checks].enabled?

    @pending_shipments.each do |shipment|
      # standard
      shipment.order_items.each do |order_item|
        errors.add(:supplier, "Order Item: #{order_item.product.name} is out of stock. Please remove from order.") if order_item.variant.quantity_available <= 0
        check_lto_max_remaining_qty(order_item) if Feature[:limited_time_offer_feature].enabled? && order_item.product.limited_time_offer?
      end
    end

    check_pre_sale_max_remaining_qty

    errors.empty?
  end

  def check_pre_sale_max_remaining_qty
    @pre_sale_shipments.each do |shipment|
      shipment.order_items.each do |order_item|
        product_pre_sales = pre_sale_max_remaining_qty[order_item.variant.product_id]
        supplier_pre_sale = product_pre_sales&.dig(:supplier_ids, order_item.supplier_id)

        if product_pre_sales.nil? || supplier_pre_sale.blank?
          errors.add(:supplier, "We couldn't find pre sale for #{order_item.variant.product_name}")
          return nil
        end
        errors.add(:supplier, "The pre sale for #{order_item.variant.product_name} didn't start") if product_pre_sales[:start_at] > Time.zone.now

        max_quantity = supplier_pre_sale[:max_quantity]

        next if max_quantity.nil? || order_item.quantity <= max_quantity

        message = if max_quantity.negative?
                    "The pre sale for #{order_item.variant.product_name} is unavailable"
                  else
                    "You can only buy #{max_quantity} #{'quantity'.pluralize(max_quantity)} of #{order_item.variant.product_name}"
                  end

        errors.add(:supplier, message)
      end
    end
  end

  def check_lto_max_remaining_qty(order_item)
    product = order_item.product
    max_quantity = product.limited_time_offer_remain_quantity

    return if product.limited_time_offer_global_limit.zero? || product.limited_time_offer_global_limit.negative? || order_item.quantity <= max_quantity

    message = if max_quantity.zero?
                "Order Item: #{order_item.product.name} is out of stock. Please remove from order."
              else
                "You can only buy #{max_quantity} #{'quantity'.pluralize(max_quantity)} of #{order_item.product.name}"
              end

    errors.add(:supplier, message)
  end

  def pre_sale_max_remaining_qty
    @pre_sale_max_remaining_qty ||=
      pre_sale_query
        .pluck(:product_id, :price, :starts_at, :supplier_ids)
        .to_h do |(product_id, price, start_at, supplier_ids)|
        [
          product_id,
          {
            price: price,
            start_at: start_at,
            supplier_ids: (supplier_ids || []).to_h do |(supplier_id, max_quantity)|
              [supplier_id, { max_quantity: max_quantity }]
            end
          }
        ]
      end
  end

  def pre_sale_query
    PreSale
      .active
      .joins(<<-SQL.squish)
        LEFT JOIN (#{pre_sale_product_order_limits.to_sql}) "product_order_limits"
        ON "product_order_limits"."id" = "pre_sales"."product_order_limit_id"
    SQL
      .where(product_id: pre_sale_product_ids)
  end

  def pre_sale_product_ids
    @pre_sale_shipments.flat_map { |shipment| shipment.order_items.map { |order_item| order_item.variant.product_id } }
  end

  def pre_sale_product_order_limits
    ProductOrderLimit
      .joins(:supplier_product_order_limits, state_product_order_limits: :state)
      .where(supplier_product_order_limits: { supplier_id: pre_sale_supplier_ids })
      .where('"states"."abbreviation" = ? OR "states"."id" = ?', @order.ship_address.state_name, @order.ship_address.state_id)
      .group(:id)
      .select(:id, <<-SQL.squish)
      array_agg(
        Array[
          "supplier_product_order_limits"."supplier_id",
          (SELECT min(limits) FROM unnest(
            Array [
              #{pre_sale_min_limits('product_order_limits', 'global_order_limit')},
              #{pre_sale_min_limits('supplier_product_order_limits')},
              #{pre_sale_min_limits('state_product_order_limits')}
            ]::bigint[]
          ) limits)
        ]
      ) as supplier_ids
    SQL
  end

  def pre_sale_supplier_ids
    @pre_sale_shipments.flat_map { |shipment| shipment.order_items.map(&:supplier_id) }
  end

  def pre_sale_min_limits(table, order_limit = 'order_limit', qty = 'current_order_qty')
    <<-SQL.squish
      case
      when "#{table}"."#{order_limit}" = 0 OR "#{table}"."#{order_limit}" IS NULL then NULL
      else "#{table}"."#{order_limit}" - "#{table}"."#{qty}"
      end
    SQL
  end

  def produce_finalize_kafka_message!
    @order.bar_os_order_send!(:finalize)
    # Refactor to reuse data from finalize
    return if @pre_sale_shipments.present? || @back_order_shipments.present? || @delayed_payment_shipments.present?

    @order.bar_os_order_send!(:paid)
  end

  def delay_payments?
    return false unless Feature[:delay_payments_non_endemic].enabled?

    storefront.non_endemic? && @order.shipments.count >= 2
  end

  def delay_payments!
    return unless delay_payments?

    @delayed_payment_shipments = @pending_shipments
    @pending_shipments = []
  end

  def add_delayed_job!
    return if @delayed_payment_shipments.empty?

    Charges::StaggerChargeService.new(@order).call
  end

  def storefront
    @storefront ||= @order.storefront
  end
end

