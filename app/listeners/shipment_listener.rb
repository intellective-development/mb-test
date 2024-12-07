class ShipmentListener < Minibar::Listener::Base
  subscribe_to Shipment, Comment, OrderAdjustment, SupplierHoliday

  def shipment_paid(shipment)
    ShipmentDeliveryEstimateWorker.perform_async(shipment.id)
    Shipment::UpdateInventoryWorker.perform_async(shipment.id)
    SupplierOnfleetNotificationWorker.perform_async(shipment.id)

    ShipmentConfirmationReminderWorker.perform_at(shipment.scheduled_for? ? shipment.scheduled_for.to_datetime - 5.minutes : 14.minutes.from_now, shipment.id)
    ShipmentConfirmationCheckWorker.perform_at(shipment.shipping_method.confirmation_time.minutes.from_now, shipment.id)
    ShipmentUnconfirmedCommentWorker.perform_at(shipment.shipping_method.automatic_supplier_comment_time.minutes.from_now, shipment.id) unless shipment.scheduled_for

    if (supplier_delivery_service = shipment.supplier&.delivery_service)
      RequestDeliveryServiceWorker.perform_async(shipment.id) if supplier_delivery_service&.name == 'Point Pickup'

      if shipment.scheduled_for.present?
        # Send internal message if no driver has accepted the task 30 minutes before delivery window
        DeliveryServiceReminderWorker.perform_at(shipment.scheduled_for.to_datetime - 30.minutes, shipment.id, true, 30)
      end
    end

    Shipment::SendPaymentCompletedEventWorker.perform_async(shipment.id)

    shipment.order_items.includes(:product).each do |item|
      next unless item.product.limited_time_offer?

      Products::LimitedTimeOffer::IncreaseSoldQuantity.call(item.product, item.quantity)
    end

    shipment.notify_deals_shipment_paid
  end

  def shipment_no_tracking_number(shipment)
    # TECH-3868 create a comment for the supplier if no tracking number was added
    shipment.add_no_tracking_number_comment
    shipment.send_tracking_number_reminder if shipment.supplier.notify_no_tracking_number?
  end

  def supplier_holiday_created(supplier_holiday)
    supplier_holiday.check_scheduled_shipments
  end

  def order_adjustment_created(order_adjustment)
    MinibarDashboardNotificationWorker.perform_async(order_adjustment.shipment_id, 'fetch_adjustment')
  end

  def comment_created(comment, liquid: false)
    return unless comment.commentable_type == 'Shipment'
    return if comment.order&.verifying?

    shipment = Shipment.find(comment.commentable_id)
    shipment.liquid = liquid
    shipment.send_update_event
    MinibarDashboardNotificationWorker.perform_async(comment.commentable_id, 'fetch_comment')
  end

  def shipment_confirmed(shipment)
    unless shipment.delivery_service_order.present? || ['Point Pickup', nil].include?(shipment.delivery_service&.name)
      RequestDeliveryServiceWorker.perform_async(shipment.id)

      if shipment.scheduled_for.nil?
        supplier_delivery_service = shipment.supplier&.delivery_service

        # Send internal message if time minutes has elapsed since requesting a driver, but no driver has accepted the task yet
        case supplier_delivery_service&.name
        when 'Point Pickup'
          DeliveryServiceReminderWorker.perform_at(45.minutes.from_now, shipment.id, false, 45)
        when 'DoorDash'
          DeliveryServiceReminderWorker.perform_at(30.minutes.from_now, shipment.id, false, 30)
        when 'CartWheel'
          DeliveryServiceReminderWorker.perform_at(30.minutes.from_now, shipment.id, false, 30)
        when 'Uber'
          DeliveryServiceReminderWorker.perform_at(30.minutes.from_now, shipment.id, false, 30)
        when 'DeliverySolutions'
          DeliveryServiceReminderWorker.perform_at(30.minutes.from_now, shipment.id, false, 30)
        when 'Zifty'
          DeliveryServiceReminderWorker.perform_at(30.minutes.from_now, shipment.id, false, 30)
        end
      end
    end

    begin
      shipment.order.confirm! if shipment.sibling_shipments.not_in_state(:confirmed, :delivered, :en_route).none?
    rescue Statesman::TransitionFailedError, Statesman::InvalidTransitionError => e
      Rails.logger.error "#{e.message}\nShipment UUID: #{shipment.uuid}. Order number: #{shipment.order.number}. Retrying in Order::AttemptOrderConfirmation worker..."

      Order::AttemptOrderConfirmationWorker.perform_async(shipment.order_id)
    end

    Shipment::PickupConfirmationWorker.perform_at(5.minutes.from_now, shipment.id) if shipment.pickup?
    Shipment::CreateGiftCardWorker.perform_async(shipment.id) if shipment.digital?
    Shipment::GiftCardVariantRefillWorker.perform_in(3.minutes, shipment.id) if shipment.digital?
    GiftOrderEventWorker.perform_async(shipment.order_id, :shipment_confirmed)
    ProductRouting::IncreaseOrderQtyWorker.perform_async(shipment.id, DateTime.now)
    Supplier::IncreaseDailyShippingCountWorker.perform_async(shipment.id) if increase_supplier_daily_shipping_count?(shipment)
  end

  def shipment_order_items_changed(shipment)
    Dashboard::DashboardService.update_order_items(shipment)
  end

  def shipment_address_updated(shipment)
    Dashboard::DashboardService.update_address(shipment)
  end

  def increase_supplier_daily_shipping_count?(shipment)
    shipment.shipping_method.shipped? && shipment.order.storefront.business_id == Business::RESERVEBAR_ID
  end

  def shipment_canceled(shipment)
    siblings_shipments = shipment.sibling_shipments
    sibling_shipments_canceled = siblings_shipments.all? { |s| s.canceled? || s.test? }
    if !(siblings_shipments.empty? || sibling_shipments_canceled) && shipment.order.all_gift_card_coupons.any?
      # if all shipments are canceled or no more, there's an order callback to handle GC refund
      Coupon::ShipmentGiftCardRefundWorker.perform_async(shipment.id)
    end
    Coupon::GiftCardExpireWorker.perform_async(shipment.order_item_ids)

    check_last_shipment(shipment) if siblings_shipments.present?

    order = shipment.order
    if siblings_shipments.empty? || sibling_shipments_canceled
      reason = shipment.cancellation_reason_id.present? ? OrderAdjustmentReason.find(shipment.cancellation_reason_id) : nil
      note = 'This order has been canceled. Order had only one active shipment and it was canceled.'

      if shipment.supplier.dashboard_type == Supplier::DashboardType::SEVEN_ELEVEN
        reason = OrderAdjustmentReason.find_by(name: 'This order has been canceled. Order only has one shipment and it was canceled by 7-Eleven.')
        note = 'This order has been canceled. Order had only one active shipment and it was canceled by 7-Eleven.'
      end

      comment = order.comments.new(note: note)
      order.order_canceled!(reason_id: reason&.id)
      comment.save!
    else
      order.try_deliver
    end
    Products::LimitedTimeOffer::DecreaseSoldQuantityWorker.perform_async(shipment.id) if shipment.order_items.includes(:product).any? { |oi| oi.product.limited_time_offer? }
  end

  def shipment_delivered(shipment)
    AvalaraInvoiceWorker.perform_async(shipment.id)

    order = shipment.order

    Order::SendOrderFulfilledEventWorker.perform_async(order.id) if (shipment.pre_sale? || shipment.back_order?) && order.all_shipments_delivered?

    check_last_shipment(shipment)

    order.try_deliver
  end

  def shipment_delayed_payment(shipment)
    Supplier::DashboardShipmentNotificationWorker.perform_async(shipment.id)
    Supplier::ShipmentNotificationWorker.perform_async(shipment.id)
    shipment.order.place! if shipment.sibling_shipments.not_in_state(:pre_sale, :back_order, :paid, :confirmed).none? && shipment.order.can_transition_to?(:placed)
  end

  def shipment_state_changed(shipment)
    return if %w[paid ready_to_ship back_order pre_sale].include?(shipment.state) && Shipment::CancelTestShipmentService.test_shipment?(shipment)

    ShipmentDashboardNotificationWorker.perform_async(shipment.id, shipment.state)
  end

  def check_last_shipment(shipment)
    return unless Feature[:split_avalara_transaction].enabled?

    uncompleted_siblings = shipment.sibling_shipments.not_in_state(ShipmentStateMachine::COMPLETED_STATES)
    AvalaraOrderInvoiceWorker.perform_async(shipment.order.id) if uncompleted_siblings.empty?
  end
end
