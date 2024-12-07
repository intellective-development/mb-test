class Admin::Fulfillment::OrdersController < Admin::Fulfillment::BaseController
  skip_before_action :verify_authenticity_token, if: :json_request?

  helper_method :sort_column, :sort_direction

  before_action :load_order, only: %i[
    cancel_dialogue cancel_order confirm_order destroy push_dialogue push_order schedule_order
    send_message send_notification send_text update apply_gift_card remove_membership_plan
    deliver_order
  ]

  before_action :get_shipment_to_comment, only: %i[
    send_message
    send_notification
    send_text
  ]

  before_action :load_shipment, only: [:cancel_shipment]

  def index
    @scheduled_order_count = get_scheduled_orders(Order.joins(:shipments)).count

    filters = {}
    filters[:order_state] = params[:order_state] if params[:order_state].present?
    filters[:suppliers] = params[:supplier_id] if params[:supplier_id].present?
    filters[:storefront] = params[:storefront_id] if params[:storefront_id].present?

    @ufilters = {}
    @ufilters[:unconfirmed_type] = params[:unconfirmed_type] || []

    @orders = Order.search(params[:query] || '*',
                           where: filters,
                           order: [{ _score: :desc }, { completed_at: { order: :desc } }],
                           misspellings: false,
                           per_page: 25,
                           page: pagination_page)

    unless @hide_unconfirmed
      @unconfirmed_orders = Order.joins(:shipments).unconfirmed.where(shipments: { state: %w[ready_to_ship paid] })
      @unconfirmed_orders = @unconfirmed_orders.joins(shipments: :shipping_method).where(shipping_methods: { shipping_type: @ufilters[:unconfirmed_type] }) unless @ufilters[:unconfirmed_type].empty?
      @unconfirmed_orders = @unconfirmed_orders.includes(:user, :shipments).order(completed_at: :desc).page(pagination_unconfirmed_page).per(pagination_unconfirmed_per_page)
      @unconfirmed_orders_uniq = @unconfirmed_orders.distinct
      @unconfirmed_orders_count = @unconfirmed_orders_uniq.total_count
    end
  end

  def show
    @order = Order.includes([:user, { shipments: :comments }, { order_items: %i[variant tax_rate] }])
                  .find(params[:id])

    respond_to do |format|
      format.html
      format.xml { render xml: @order }
    end
  end

  def edit
    @order = Order.includes([
                              :user,
                              :ship_address,
                              :payment_profile,
                              :fraud_score,
                              :disputes,
                              :storefront,
                              { order_suppliers: [:address] },
                              { order_adjustments: %i[reason supplier user] },
                              { shipments: %i[supplier metadata order_items shipment_amount shipping_method tracking_detail applied_deals] }
                            ]).find(String(params[:id]))

    sift_response = Fraud::Score.sift_score_and_reasons(@order.user)
    @promo_abuse_results = Fraud::Score.promo_abuse_reasons(sift_response)
    @promo_abuse_decision_id = Fraud::Score.promo_abuse_latest_decision(sift_response)
    @promo_abuse_check_status = case @promo_abuse_decision_id
                                when 'looks_bad_promotion_abuse'
                                  'failed'
                                when 'unreviewed_user_promotion_abuse'
                                  'pending'
                                else
                                  'pass'
                                end
    @related_accounts = Fraud::Score.list_fraudulent_accounts(sift_response)
    @related_accounts.each do |_abuse_type, abuse_value|
      next unless abuse_value

      abuse_value[:reasons]&.each do |reason|
        reason[:accounts]&.map! do |referral_code|
          user = User.find_by(referral_code: referral_code)
          { id: user.id, code: referral_code, email: user.account.email } if user
        end
        reason[:accounts]&.compact!
      end
    end

    @fraud_record = @order.fraud_record || FraudulentOrder.new
    @initial_related_accounts = @fraud_record.related_user_ids.map do |user_id|
      user = User.find(user_id)
      { id: user_id, code: user.referral_code, email: user.account.email } if user
    end.compact

    expires_in 5.minutes, public: false
    respond_to(&:html) if stale?(etag: @order, last_modified: @order.updated_at)
  end

  def update_notes
    @order = Order.find(params[:id])
    return render status: '404' if @order.nil?

    if params.key?(:order)
      @order.delivery_notes = params[:order][:delivery_notes] if params[:order].key?(:delivery_notes)
      @order.shipments.each do |shipment|
        shipment.comments.create(
          note: 'This order has updated delivery instructions. We suggest you reprint the order slip, which has been updated with the correct information.',
          created_by: current_user.id,
          user_id: @order.user_id,
          posted_as: :minibar
        )
      end
    elsif params.key?(:gift_detail)
      return render status: '400' if @order.gift_detail.nil?

      @order.gift_detail.message = params[:gift_detail][:message] if params[:gift_detail].key?(:message)
      @order.shipments.each do |shipment|
        shipment.comments.create(
          note: 'This order is a gift and should be gift wrapped with note. The gift note has been updated. We suggest you reprint the order slip, which has been updated with the correct information.',
          created_by: current_user.id,
          user_id: @order.user_id,
          posted_as: :minibar
        )
      end

      Segment::SendOrderUpdatedEventWorker.perform_async(@order.id, :gift_message_updated)
    else
      return render status: '400'
    end

    @order.updated_at = Time.current
    if @order.save
      redirect_to edit_admin_fulfillment_order_path, id: params[:id]
    else
      render status: '500'
    end
  end

  def confirm_order
    @order.order_confirmed!
    if @order.save
      @order.confirm_digital_shipments!
      redirect_to admin_fulfillment_orders_path
    else
      render status: '500'
    end
  end

  def push_dialogue
    render :push_dialogue, layout: false
  end

  def push_order
    render status: '500' unless \
      @order.finalize &&
      @order.verify &&
      @order.pay

    redirect_to edit_admin_fulfillment_order_path(@order.number), notice: 'Order has been pushed successfully.'
  end

  def cancel_dialogue
    @reasons = OrderAdjustmentReason.cancellation_reasons.active.pluck(:name, :id)
    @shipment = Shipment.find(params[:shipment_id]) if params[:shipment_id]
    @supplier = @shipment.try(:supplier) if @shipment
    @user = current_user
    @order_adjustment = @order.order_adjustments.new

    if !Feature[:disable_oos_availability_check].enabled? && @order.storefront.enable_oos_availability_check && @shipment.present?
      order_items = @shipment.order_items.includes(:product)
      product_ids = order_items.map(&:product_id)
      product_grouping_ids_with_prefix = order_items.pluck('products.product_grouping_id').map { |grouping_id| "GROUPING-#{grouping_id}" }
      product_ids_with_prefix = product_ids.map { |pid| "PRODUCT-#{pid}" }

      @new_eligible_suppliers_with_variants = []

      begin
        rsa_products = RSA::MultiSelectService.call(@order.storefront_id, product_grouping_ids_with_prefix, product_ids_with_prefix, nil, nil, @shipment.address, include_other_retailers: true)

        rsa_products = rsa_products.select do |p|
          p.shipping_method == @shipment.shipping_type.to_sym &&
            p.supplier.id != @shipment.supplier_id &&
            product_ids.include?(p.product_id) &&
            (!@shipment.engraving? || (@shipment.engraving? && p.type.to_sym == :engraving)) &&
            !Variant.find_by(id: p.variant_id)&.sold_out?
        end

        rsa_products_by_product_ids_grouped = rsa_products.group_by { |p| p.supplier.name }
        rsa_products_by_product_ids_grouped.each do |supplier_name, products|
          if order_items.count == 1
            products.each do |p|
              @new_eligible_suppliers_with_variants << ["#{supplier_name} - $#{p.price.to_f * order_items.last.quantity}", p.variant_id.to_s]
            end
          elsif order_items.count > 1 && Set.new(order_items.pluck('products.id')) == Set.new(products.pluck(:product_id))
            @new_eligible_suppliers_with_variants << ["#{supplier_name} - $#{products.pluck(:price).map(&:to_f).sum}", products.pluck(:variant_id).join(',')]
          end
        end

        @new_eligible_suppliers_with_variants = @new_eligible_suppliers_with_variants.uniq.sort
      rescue StandardError => e
        Rails.logger.error("An error occurred while calling RSA::MultiSelectService: #{e.message}")
      end
    end

    render :cancel_dialogue, layout: false
  end

  def resolve_exception
    shipment = Shipment.find(params[:id])

    previous_state = shipment.shipment_transitions[-2]&.to_state&.to_sym
    if shipment.transition_to!(previous_state)
      shipment.comments.create(note: params[:resolution].to_s, created_by: current_user.id)

      redirect_to edit_admin_fulfillment_order_path(shipment.order_number), notice: 'Exception was resolved.'
    else
      redirect_to edit_admin_fulfillment_order_path(shipment.order_number), notice: 'Unable to resolve exception.'
    end
  end

  def generate_payment_link
    shipment = Shipment.find(params[:id])

    shipment.order.create_payment_profile_update_link
    shipment.order.comments.create(note: 'Payment profile update link generated.', created_by: current_user.id)
    redirect_to edit_admin_fulfillment_order_path(shipment.order_number), notice: 'Payment profile update link has been generated.'
  end

  def cancel_shipment
    adjustment_params = params[:order_adjustment]

    if params[:new_variant_ids].present? && !OrderAdjustmentReason.find_by(id: adjustment_params[:reason_id])&.out_of_stock?
      flash[:alert] = 'Unable to cancel the shipment and switch the supplier. Please make sure that you selected a candidate supplier and the cancellation reason is \'out_of_stock\'.'

      redirect_to edit_admin_fulfillment_order_path(@shipment.order_number) and return
    end

    new_variant_ids = params[:new_variant_ids].split(',').map(&:to_i) if params[:new_variant_ids].present?

    attrs = cancel_adjustment_attrs(@shipment, adjustment_params)
    adjustment = @shipment.order_adjustments.new(attrs)

    reason = OrderAdjustmentReason.find_by(name: 'Cancellation Fee')
    fee_adjustment = if adjustment_params[:cancellation_fee] && adjustment_params[:cancellation_fee].to_f > 0.0
                       fee_attrs = cancellation_fee_adjustment_attrs(@shipment, adjustment_params[:cancellation_fee], reason)
                       @shipment.order_adjustments.new(fee_attrs)
                     end

    ActiveRecord::Base.transaction do
      fee_adjustment&.save!
      @shipment.cancel!
      comment = @shipment.order.comments.new(note: "#{@shipment.supplier_name} Shipment was canceled.", created_by: current_user.id)

      @shipment.cancellation_reason_id = adjustment_params[:reason_id]
      @shipment.cancellation_notes = adjustment_params[:description]
      @shipment.save!

      adjustment.save!
      comment.save!

      CancelDeliveryServiceWorker.perform_async(@shipment.id, @shipment.delivery_service.id, false) if @shipment.delivery_service

      if !Feature[:disable_oos_availability_check].enabled? && @shipment.order.storefront.enable_oos_availability_check && new_variant_ids.present?
        order_items = @shipment.order_items

        order_item_candidates = new_variant_ids.map do |new_variant_id|
          new_variant = Variant.find_by(id: new_variant_id)
          quantity = order_items.find { |oi| oi.product.id == new_variant.product_id }&.quantity

          raise SupplierSwitchingForOosProducts::Errors::ArgumentError, "New variant with id #{new_variant_id} does not exist" if new_variant.nil?
          raise SupplierSwitchingForOosProducts::Errors::ArgumentError, 'Original quantity cannot be nil' if quantity.nil?
          raise SupplierSwitchingForOosProducts::Errors::ArgumentError, "New variant's available quantity cannot be smaller than the original quantity" if new_variant.quantity_available < quantity

          { 'variant_id' => new_variant_id, 'quantity' => quantity }
        end.compact

        result = SupplierSwitchingForOosProducts::CreateOrderService.call(old_shipment_uuid: @shipment.uuid, order_item_candidates: order_item_candidates)

        raise SupplierSwitchingForOosProducts::Errors::OrderCreationError, result.error unless result.success?
      end

      flash[:notice] = 'Shipment Cancelled'
    rescue StandardError => e
      Rails.logger.error e
      flash[:alert] = "Unable to cancel shipment. Here's the error: (#{e.message})"

      raise ActiveRecord::Rollback
    ensure
      redirect_to edit_admin_fulfillment_order_path(@shipment.order_number)
    end
  end

  def cancel_order
    adjustments = []
    adjustment_params = params[:order_adjustment]

    reason = OrderAdjustmentReason.find_by(name: 'Cancellation Fee')
    cancellation_fee = adjustment_params[:cancellation_fee].to_f if adjustment_params[:cancellation_fee] && adjustment_params[:cancellation_fee].to_f > 0.0

    @order.shipments.each do |shipment|
      attrs = cancel_adjustment_attrs(shipment, adjustment_params)
      adjustments << shipment.order_adjustments.new(attrs)
      fee_adjustment = if cancellation_fee && cancellation_fee > 0.0
                         shipment_cancelation_fee = [cancellation_fee, shipment.shipment_total_amount].min
                         cancellation_fee -= shipment_cancelation_fee
                         fee_attrs = cancellation_fee_adjustment_attrs(shipment, shipment_cancelation_fee, reason)
                         shipment.order_adjustments.new(fee_attrs)
                       end
      adjustments << fee_adjustment if fee_adjustment

      shipment.cancellation_reason_id = adjustment_params[:reason_id]
      shipment.cancellation_notes = adjustment_params[:description]
      shipment.save!
    end

    # if reason is fraud (reason_id) then send over for cancellation and flagging
    @order.order_canceled!(send_confirmation_email: params[:send_confirmation_email], reason_id: adjustment_params[:reason_id])
    if adjustments.map(&:save) && @order.save
      @order.order_suppliers.each do |supplier|
        next if supplier.delivery_service_id.blank?

        CancelDeliveryServiceWorker.perform_async(@order.id, supplier.delivery_service_id, true)
      end

      redirect_to edit_admin_fulfillment_order_path(@order.number), notice: 'Order Cancelled'
    else
      redirect_to edit_admin_fulfillment_order_path(@order.number), alert: 'Unable to Cancel Order'
    end
  end

  def retry_notification
    shipment = Shipment.find(params[:shipment][:id])
    if params[:select_all]
      notification_methods = shipment.supplier.notification_methods.where(notification_type: 1)
      if notification_methods
        notification_methods.each do |notification_method|
          notification_method.send_notification(shipment)
        end
        redirect_to edit_admin_fulfillment_order_path(params[:id]), notice: 'Notification sent'
      else
        redirect_to edit_admin_fulfillment_order_path(params[:id]), alert: 'Unable to resend notification'
      end
    else
      notification_method = shipment.supplier.notification_methods.find(params[:notification_method_id])
      if notification_method
        notification_method.send_notification(shipment)
        redirect_to edit_admin_fulfillment_order_path(params[:id]), notice: 'Notification sent'
      else
        redirect_to edit_admin_fulfillment_order_path(params[:id]), alert: 'Unable to resend notification'
      end
    end
  end

  def send_message
    message = params[:message]['message']
    text_message = params[:message]['text_message']
    if @order.nil? || message.blank?
      flash[:alert] = 'Missing parameters. Unable to send message'
    else
      comment_saved = true
      @shipments.each do |shipment|
        comment = shipment.comments.new(note: "SENT TO CUSTOMER: #{text_message}", created_by: current_user.id)
        comment_saved &= comment.save ? true : false
      end
      if comment_saved && @shipments.count.nonzero? # if both saved, and did enter that loop
        CustomerNotifier.order_customer_service_comment(@order.id, message).deliver_later
        flash[:notice] = 'Message sent to customer'
      end
    end
    redirect_to action: :edit
  end

  def send_text
    text = params[:text]['text']
    phone = params[:text]['phone']

    if @order.nil? || phone.nil? || text.blank?
      flash[:alert] = 'Missing parameters. Unable to send text'
    else
      comment_saved = true
      @shipments.each do |shipment|
        comment = shipment.order.comments.new(note: "Text:#{text}", created_by: current_user.id)
        comment_saved &= comment.save ? true : false
      end
      if comment_saved && @shipments.count.nonzero? # if both saved, and did enter that loop
        PhoneNotification.sms_message(phone, text, Settings.twilio.customer_number)
        flash[:notice] = 'Text sent to customer'
      end
    end
    redirect_to action: :edit
  end

  def send_notification
    message = params[:notification]['notification']
    if @order.nil? || message.blank?
      flash[:alert] = 'Missing parameters. Unable to send message'
    else
      comment_saved = true
      @shipments.each do |shipment|
        comment = shipment.comments.new(note: "PUSH NOTIFICATION SENT TO CUSTOMER: #{message}", created_by: current_user.id)
        comment_saved &= comment.save ? true : false
      end
      if comment_saved && @shipments.count.nonzero? # if both saved, and did enter that loop
        PushNotificationWorker.perform_async(:custom_message, @order.user.email, { content: message })
        flash[:notice] = 'Message sent to customer'
      end
    end
    redirect_to action: :edit
  end

  def schedule_order
    if @order.can_be_rescheduled?
      @order.scheduled_for = Time.zone.parse(params[:scheduled][:for])
      @order.transition_to!(:scheduled, { user_id: current_user.id })

      @order.order_suppliers.each do |supplier|
        delivery_service_id = supplier.delivery_service_id
        RescheduleDeliveryServiceWorker.perform_async(@order.id, delivery_service_id) unless delivery_service_id.nil?
      end
      flash[:notice] = "Order Scheduled for #{@order.scheduled_for.strftime('%D %R')}"
    else
      flash[:error] = 'Sorry, this order cannot be scheduled.'
    end

    redirect_to action: :edit
  end

  def deliver_order
    if @order.shipments.all? { |shipment| shipment.can_transition_to?(:delivered) }
      @order.shipments.each do |shipment|
        metadata_updates = { delivered_at: Time.zone.now }

        shipment.metadata ||= ShipmentMetadata.new
        shipment.metadata.update(metadata_updates)
        shipment.deliver!
      end
      @order.confirm!
      flash[:notice] = 'Order delivered'
    else
      flash[:error] = 'Sorry, this order cannot be delivered.'
    end

    redirect_to action: :edit
  end

  def process_complete
    @order = Order.find_by(number: params[:id])
    if @order
      @order.process_complete_order({ skip_legal_age_agreement: true })
      flash[:notice] = 'Order Processed'
    else
      flash[:error] = 'Invalid Order'
    end
    redirect_to action: :edit
  end

  def skip_verification
    @order = Order.find_by(number: params[:id])
    @order.pay!

    redirect_to action: :edit, notice: 'Order processed.'
  end

  def cancel_complete
    @order = Order.find_by(number: params[:id])
    if @order
      @order.cancel_complete_order
      flash[:notice] = 'Order Cancelled'
    else
      flash[:error] = 'Invalid Order'
    end
    redirect_to action: :edit
  end

  def tags
    @order = Order.find_by(number: params[:id])
    @tags = params[:order][:tag_list].strip
    @order.tag_list = @tags
    redirect_to edit_admin_fulfillment_order_path(@order.number) if @order.save
  end

  def invoice
    @order = Order.includes([:user, { shipments: :comments }, { order_items: %i[variant tax_rate] }])
                  .find(params[:id])

    respond_to do |format|
      format.html
      format.xml { render xml: @order }
    end
  end

  def pdf
    @order ||= Order.includes([{ order_items: [{ variant: :product }, :order, :supplier, :product, :product_type, :tax_rate] }, { shipments: :order_items }, { order_suppliers: :supplier_type }])
                    .find(params[:id])
    render template: 'account/orders/pdf', layout: false
  end

  def remove_item
    order_item = OrderItem.find params[:order_item_id]
    @order = Order.find params[:order_id]
    if order_item.nil?
      flash[:alert] = 'Order Item not found'
      return redirect_to action: 'edit', controller: 'admin/fulfillment/orders', id: @order.number, error: flash[:alert]
    end

    @shipment = order_item.shipment
    current_supplier = @shipment.supplier

    if @shipment.order_items.size == 1
      if params[:new_variant_id].present?
        oos_reason = OrderAdjustmentReason.find_by(reporting_type: 'out_of_stock', name: 'Out of Stock')

        params[:new_variant_ids] = params[:new_variant_id].to_s
        params[:order_adjustment] = { reason_id: oos_reason.id }
      else
        reason = OrderAdjustmentReason.find_by(name: 'Order Change - Item Removed from Order (Not OOS, Customer Requested)')

        params[:order_adjustment] = { reason_id: reason.id }
      end

      return cancel_shipment
    end

    @shipment.remove_order_item(order_item, current_user.id)
    @order.reload.bar_os_order_send!(:update_line_items)

    Segment::SendOrderUpdatedEventWorker.perform_async(@order.id, :item_removed)
    Segment::SendProductsRefundedEventWorker.perform_async(@order.id, order_item.id)

    if !Feature[:disable_oos_availability_check].enabled? && @order.storefront.enable_oos_availability_check && params[:new_variant_id].present?
      order_item_candidate = { 'variant_id' => params[:new_variant_id], 'quantity' => order_item.quantity }

      result = SupplierSwitchingForOosProducts::CreateOrderService.call(old_shipment_uuid: @shipment.uuid, order_item_candidates: [order_item_candidate])

      raise SupplierSwitchingForOosProducts::Errors::OrderCreationError, result.error unless result.success?
    end

    flash[:notice] = 'Item Removed.'

    redirect_to action: 'edit', controller: 'admin/fulfillment/orders', id: @order.number
  rescue SupplierSwitchingForOosProducts::Errors::OrderCreationError => e
    Rails.logger.error e

    flash[:alert] = "Unable to switch supplier. Here's the error: (#{e.message})"

    redirect_to action: 'edit', controller: 'admin/fulfillment/orders', id: @order.number
  end

  def apply_gift_card
    code = params[:code].to_s.downcase.squish
    error = nil

    begin
      Coupons::DecreasingBalance::AddToOrderWithAdjustment.new(order: @order, coupon_code: code, user: current_user).call
    rescue GiftCardException::AlreadyCoveredError => e
      error = 'The order is already covered by coupons/gift cards.'
    rescue GiftCardException::DigitalOrderError => e
      error = "Gift Cards can't be applied on digital orders"
    rescue GiftCardException::ZeroBalanceError => e
      error = 'The gift card has 0 balance.'
    rescue GiftCardException::InvalidCodeError => e
      error = "Gift Card with code '#{code.upcase}' not found."
    rescue GiftCardException::OrderAdjustmentError => e
      error = 'There was an error trying to process the order adjustment'
    rescue RuntimeError => e
      error = "The gift card '#{code.upcase}' is invalid."
    end

    if error
      flash[:error] = error
    else
      flash[:notice] = "Gift Card '#{code.upcase}' added to order successfully!"
    end

    redirect_to action: 'edit', id: @order.number
  end

  def remove_membership_plan
    if @order.membership_plan_id.blank?
      flash[:alert] = 'Membership not found'
      return redirect_to action: 'edit', controller: 'admin/fulfillment/orders', id: @order.number, error: flash[:alert]
    end

    result = Order::RemoveMembershipPlan.new(order: @order, user: current_user, force: true).call

    unless result.success?
      flash[:alert] = result.error || 'Membership plan could not be removed from the order.'
      return redirect_to action: 'edit', controller: 'admin/fulfillment/orders', id: @order.number, error: flash[:alert]
    end

    flash[:notice] = 'Membership Removed.'
    redirect_to action: 'edit', controller: 'admin/fulfillment/orders', id: @order.number
  end

  protected

  def load_order
    @order = Order.find(params[:id])
  end

  def load_shipment
    @shipment = Shipment.find(params[:id])
  end

  def cancel_adjustment_attrs(shipment, params)
    {
      user_id: current_user.id,
      shipment_id: shipment.id,
      reason_id: params[:reason_id],
      description: params[:description].presence || 'Cancelled by Minibar CX',
      financial: false,
      braintree: false,
      credit: 0.0,
      amount: 0.0
    }
  end

  def cancellation_fee_adjustment_attrs(shipment, amount, reason)
    {
      user_id: current_user.id,
      shipment_id: shipment.id,
      reason_id: reason.id,
      description: 'Supplier cancellation fee',
      financial: true,
      braintree: true,
      credit: false,
      amount: amount
    }
  end

  def sort_column
    params[:sort] || 'order_completed_at'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'desc'
  end

  def get_shipment_to_comment
    params_holder = params[:message].presence || params[:text].presence || params[:notification]
    if params_holder
      to_comment = params_holder['shipment']
      to_comment = @order.shipments.pluck(:id) if to_comment.blank?
      @shipments = [Shipment.find(to_comment)].flatten # one or two, converts it to simple arr
    else
      @shipments = []
    end
  end

  def get_scheduled_orders(orders)
    orders.where('shipments.state = :scheduled_state AND shipments.scheduled_for < :now', scheduled_state: 'scheduled', now: Time.zone.now)
  end

  def json_request?
    request.format.json?
  end

  def pagination_unconfirmed_page
    params[:unconfirmed_page].present? ? params[:unconfirmed_page].to_i : 1
  end

  def pagination_unconfirmed_per_page
    50
  end
end
