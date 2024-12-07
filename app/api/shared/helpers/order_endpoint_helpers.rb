# rubocop:disable Metrics/ModuleLength
module Shared::Helpers::OrderEndpointHelpers
  include SentryNotifiable

  def set_shoprunner_token
    # If the user has the ShopRunner user cookie, we use that, otherwise we allow
    # the cookie to be supplied as an optional parameter.
    if storefront.default_storefront?
      params[:shoprunner_token] = cookies[:sr_token] unless params[:shoprunner_token]
    else
      params[:shoprunner_token] = nil
    end
  end

  def calculate_order_taxes
    @order ||= @user.orders.new(doorkeeper_application: doorkeeper_application, storefront: storefront, cart_id: @cart_id)

    # Fetching fallback address for tax calculation
    # 1. We fetch address from built order (confirmed by user on checkout)
    order_address = @order.ship_address
    # 2. We fetch address from user cookie (entered on store, not confirmed)
    order_address ||= user_address

    @order.reload
    @order.recalculate_and_apply_taxes(order_address, should_set_default_tip?)
    recalculate_amounts_to_apply_coupon_values(order_address)

    @order.save!
  end

  def recalculate_amounts_to_apply_coupon_values(order_address)
    return if @params[:gift_cards].nil? && @params[:coupons].nil? && @params[:promo_code].nil?

    @order.recalculate_and_apply_taxes(order_address, should_set_default_tip?)
  end

  def create_or_update_order!(*args)
    create_or_update_order(*args)
  rescue DynamicShippingError => e
    error!(e.message, 400)
  rescue CreateOrUpdateOrderError => e
    error!(JSON.parse(e.message), 400)
  rescue ActiveRecord::RecordInvalid => e
    error!(e.message, 400)
  rescue StandardError => e
    Rails.logger.error("Unhandled create_or_update_order error: #{e.message}")
    error!('Internal server error', 500)
  end

  def create_or_update_order(skip_scheduling_check: true, skip_in_stock_check: false, skip_tax_calculation: false)
    @order ||= @user.orders.new(doorkeeper_application: doorkeeper_application, storefront: storefront, cart_id: @cart_id)

    set_shoprunner_token

    @order.promo_address = @params[:promo_address] unless @params[:promo_address].nil?
    @order.metadata = @params[:metadata] unless @params[:metadata].nil?

    order_service = OrderCreationServices.new(
      @order, @user, @cart, params, skip_scheduling_check: skip_scheduling_check,
                                    skip_in_stock_check: @order.disable_in_stock_check? || skip_in_stock_check,
                                    **fraud_options(nil, params[:session_id])
    )
    order_service.build_order

    MetricsClient::Metric.emit('order.storefront.id', @order.storefront.id)

    @order.save! # fix: without this save we seem to lose all order_association_keys attributes from creation service
    @order.order_amount&.save!

    if Feature[:skip_order_tax_calculation_feature].enabled?
      # Avalara calls take a long time. Caller should know when to skip it.
      calculate_order_taxes unless skip_tax_calculation
    else
      calculate_order_taxes
    end

    if @order.minibar?
      begin
        deal_service = Deals::ApplyDealsService.new(@order)
        deal_service.call

        # no error for deal service to get avg of errors
        MetricsClient::Metric.emit('minibar_web.orders.errors.deal_service_error', 0)
      rescue StandardError => e
        # ignoring deals errors
        MetricsClient::Metric.emit('minibar_web.orders.errors.deal_service_error', 1)
        notify_sentry_and_log(e, "Error calling deals service #{e.message}", { tags: { order_id: @order.id } })
      end
    end

    unless order_service.valid?
      @order.cancel_finalize

      raise CreateOrUpdateOrderError, order_service.error_args.first.to_json
    end

    begin
      @order.assign_attributes(client_details.as_attributes.merge(visit_id: current_visit&.id))
    rescue StandardError => e
      Rails.logger.error("Error assigning client details to order: #{e.message}")
    end
  rescue Dashboard::Integration::Errors::PublicError => e
    error!(e.error_payload, 400)
  end

  def should_set_default_tip?
    params.nil? || params.fetch(:tip, -1).nil? # client can explicitly put tip: null into order creation / update submission to request tip recalculation
  end

  def set_default_tip
    DefaultTipService.new(@order).calculate
  end

  def allows_tip?
    @order.shipping_methods.where(allows_tipping: true).exists?
  end

  def user_address
    address_params = { address: JSON.parse(cookies[:mb_address]).transform_keys(&:to_sym) }
    Address.create_from_params(address_params)
  rescue StandardError => e
    nil
  end

  def do_finalize
    finalize = FinalizeOrderService.new(@order, { legal_age_agreement: params[:age_agreement] })
    return if @order.consider_paid? && @order.shipments.pending.empty?

    if finalize.process
      SubscriptionService.create_subscription(@order, params[:replenishment][:interval]) if params[:replenishment] && params[:replenishment][:enabled]

      if @order.order_amount
        @order.order_amount.skip_coupon_creation = false
        @order.order_amount.create_balance_adjustment
      end
    else
      @order.cancel_finalize!

      message = finalize.errors.empty? ? 'Unable to process order.' : finalize.errors.values.flatten.to_sentence
      Rails.logger.warn("Order cannot be finalized. #{message}")

      error!(message, 400)
    end
  rescue StandardError => e
    message = finalize.errors.empty? ? 'Unable to process order.' : finalize&.errors&.values&.flatten&.to_sentence
    notify_sentry_and_log(e, "Order cannot be finalized. #{message}", { tags: { order_id: @order.id }, extra: { errors: finalize&.errors&.values&.flatten } })

    @order.cancel_finalize! if @order.finalizing?
    error!(message, 400)
  end

  def set_cart
    @cart = Cart.find_by(id: @params[:cart_id])
  end

  def tip_present?
    @params.nil? || @params.key?(:tip)
  end

  def build_redirection_endpoint
    base_url = @order.storefront.priority_hostname
    "https://#{base_url}/storefront/checkout?storefront_uuid=#{@order.storefront_uuid}&order_number=#{@order.number}"
  end

  def set_order
    @order = Order.find_by(number: @params[:number])
  end

  def validate_storefront_uuid!
    error!('Order not found.', 400) if @order&.storefront_uuid != params[:storefront_uuid]
  end

  def set_cart_id
    @cart_id = @params[:cart]&.[](:id)
  end

  def set_ip_address_in_params
    @params[:ip_address] = client_ip
  end

  def set_storefront_in_params
    @params[:storefront] = storefront
  end

  def guest_cart_or_owner
    return true if @cart.user&.guest_by_email?
    return true if @cart.user&.id == @user.id

    false
  end

  def with_mutex!(mutex_id, &block)
    raise ArgumentError, 'No block given' unless block

    RedisMutex.with_lock(mutex_id.to_sym, block: 0) { block.call }
  end

  def finalize_order_helper!
    if @order&.storefront&.requires_payment_partner_authentication
      with_mutex!("finalizing_order_#{@order.number}") do
        raise UnauthorizedError, 'Unauthorized.' unless valid_payment_partner_request?

        process_finalize_order!
      end
    else
      process_finalize_order!
    end
  end

  def process_finalize_order!
    if !doorkeeper_application&.allow_order_finalization
      create_or_update_order(skip_scheduling_check: false)

      raise FinalizeOrderError, 'Order is invalid' unless @order.save

      [200, 'paid']
    elsif !@order.in_progress? && !@order.finalizing?
      Rails.logger.warn("Order #{@order.id} cannot be finalized. Current state is #{@order.state}")

      [200, @order.state]
    else
      @order.birthdate = params['birthdate']
      @order.finalize! unless @order.finalizing?
      create_or_update_order(skip_scheduling_check: false)

      raise FinalizeOrderError, 'Order is invalid' unless @order.save

      do_finalize

      [200, @order.state]
    end
  end
end
# rubocop:enable Metrics/ModuleLength
