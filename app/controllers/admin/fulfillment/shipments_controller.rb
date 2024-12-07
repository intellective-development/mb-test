class Admin::Fulfillment::ShipmentsController < Account::BaseController
  layout 'minibar'

  def pdf
    @shipment = Shipment.includes([{ order: :user }, { order_items: %i[variant tax_rate] }]).find(params[:id])
    @order = @shipment.order
    @storefront = @order.storefront

    invoice_service = ShipmentInvoiceService.new(@shipment)
    @order_items = invoice_service.grouped_order_items
    @badges = invoice_service.badges
    render layout: false
  end

  def gift_card_management
    @shipment = Shipment.find(params[:id])
    @order = @shipment.order
    render layout: false
  end

  def retry_order_placement
    @shipment = Shipment.find(params[:id])
    if @shipment.state == 'ready_to_ship' && @shipment.supplier.custom_dashboard?
      ShipmentDashboardNotificationWorker.perform_async(@shipment.id)
      flash[:notice] = "Order will be re-sent to #{@shipment.supplier.dashboard_name} in a few seconds."
    end
    redirect_to edit_admin_fulfillment_order_path(@shipment.order)
  end

  def send_seven_eleven_notification
    @shipment = Shipment.find(params[:id])
    message = 'Unexpected action!'

    if @shipment.supplier.dashboard_type == Supplier::DashboardType::SEVEN_ELEVEN
      case params[:type]
      when 'oos'
        CustomerSevenElevenNotifier.out_of_stock_notification(@shipment.id).deliver
        message = '7-Eleven out of stock notification has been sent.'
      when 'cancel'
        CustomerSevenElevenNotifier.cancellation_notification(@shipment.id).deliver
        message = '7-Eleven OOS ALL Items (Advise of Cancellation) notification has been sent.'
      when 'fd'
        CustomerSevenElevenNotifier.failed_delivery_notification(@shipment.id).deliver
        message = '7-Eleven failed delivery notification has been sent.'
      end
    end

    flash[:notice] = message
    Dashboard::Integration::SevenEleven::Notes.add_note(@shipment, message)

    redirect_to edit_admin_fulfillment_order_path(@shipment.order)
  end

  def initiate_redelivery
    @shipment = Shipment.find(params[:id])

    if @shipment.supplier.dashboard_type != Supplier::DashboardType::SPECS
      flash[:notice] = "Redelivery can be only initiated for Spec's shipments!"
      redirect_to edit_admin_fulfillment_order_path(@shipment.order)
    end

    unless @shipment.exception? && @shipment.last_shipment_transition.metadata['type'] == 'failed_delivery'
      flash[:notice] = 'Redelivery can be only initiated for failed shipments!'
      redirect_to edit_admin_fulfillment_order_path(@shipment.order)
    end

    @shipment.update(delivery_service_order: nil)
    state_metadata = { redeliver: true }
    @shipment.transition_to!(:confirmed, state_metadata)

    flash[:notice] = 'Success! Redelivery will be initiated in a moment.'
    Dashboard::Integration::Specs::Notes.add_note(@shipment, 'Initiated redelivery.')

    redirect_to edit_admin_fulfillment_order_path(@shipment.order)
  end

  def schedule
    @shipment = Shipment.find(params[:id])
    render layout: false
  end

  def update_schedule
    shipment = Shipment.find params[:id]
    order = shipment.order

    if order.can_be_rescheduled? && shipment.can_be_rescheduled?
      shipment.delivered_at = nil if shipment.delivered?
      shipment.scheduled_for = params[:scheduled][:for]
      shipment.transition_to!(:scheduled, { user_id: current_user.id })
      order.touch

      Shipment::ProcessRescheduleWorker.perform_async(shipment.id)
      flash[:notice] = "Shipment Scheduled for #{shipment.scheduled_for.strftime('%D %R')}"
    else
      flash[:error] = 'Sorry, this shipment cannot be scheduled.'
    end

    redirect_to edit_admin_fulfillment_order_path(order)
  end

  def deliver
    @shipment = Shipment.find(params[:id])
    render layout: false
  end

  def update_deliver
    shipment = Shipment.find params[:id]

    if shipment.can_transition_to?(:delivered)
      metadata_updates = { delivered_at: Time.zone.now }
      shipment.metadata ||= ShipmentMetadata.new
      shipment.metadata.update(metadata_updates)
      shipment.deliver!
      flash[:notice] = 'Shipment delivered'
    else
      flash[:error] = 'Sorry, this shipment cannot be delivered.'
    end

    redirect_to edit_admin_fulfillment_order_path(shipment.order)
  end

  def expire_gift_cards
    @shipment = Shipment.find(params[:id])
    gift_cards = Coupon.where(order_item_id: @shipment.order_item_ids)
    used_gift_cards = gift_cards.select do |gift_card|
      gift_card.balance < gift_card.amount
    end
    message = 'Gift cards will be expired in the next seconds.'
    message << " Some coupons were already applied in orders: #{used_gift_cards.map(&:code).join(', ')}" if used_gift_cards.any?

    @shipment.order.touch
    flash[:notice] = message

    Coupon::GiftCardExpireWorker.perform_async(@shipment.order_item_ids)
    redirect_to edit_admin_fulfillment_order_path(@shipment.order_number)
  end

  def update_gift_cards
    @shipment = Shipment.find(params[:id])

    gift_card_service = Shipment::GiftCardUpdaterService.new(@shipment, gift_card_params, current_user)
    if gift_card_service.process!
      flash[:notice] = 'Gift cards updated!'
    else
      flash[:alert] = "There was an error trying to update the gift card options: #{gift_card_service.errors.join(', ')}"
    end

    @shipment.order.touch # flash messages
    redirect_to edit_admin_fulfillment_order_path(@shipment.order_number)
  end

  def update_engraving_options
    order_item_id = params[:order_item_id]
    order_item = OrderItem.find order_item_id
    order_item.item_options.line1 = params[:line1]
    order_item.item_options.line2 = params[:line2]
    order_item.item_options.line3 = params[:line3]
    order_item.item_options.line4 = params[:line4]
    order_item.item_options.save
  end

  def gift_card_params
    params.require(:shipment).permit(
      {
        order_items_attributes: [
          :id,
          { item_options_attributes: %i[resend message new_send_date cc_sender recipients id] },
          { coupons_attributes: %i[deleted recipient_email id] }
        ]
      }
    )
  end
end
