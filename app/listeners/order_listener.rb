class OrderListener < Minibar::Listener::Base
  subscribe_to Order, Sift::Decision

  def decision_created(decision)
    decision.applicable_orders.each do |order|
      Order::PayTransitionWorker.perform_async(order.id)
    end
  end

  def order_paid(order)
    OrderFraudScoreWorker.perform_async(order.id)
    Order::IncrementCountWorker.perform_async(order.id)
    CreateOrderAmountWorker.perform_async(order.id) unless order.order_amount
    CreatePastOrderCartShareWorker.perform_async(order.id)
    Order::ConfirmDigitalShipmentsWorker.perform_async(order.id) if order.contains_digital_shipments?
    Order::NotifyGiftCardOrderNeedsReview.perform_async(order.id) if order.contains_digital_shipments?

    Order::NotifyISPOrderFromRecentGiftCard.perform_async(order.id)

    # CreateBalanceAdjustmentWorker perform call was moved as an OrderAmount callback

    # [TECH-1551] Asana Alert for $500+ orders
    if order.taxed_total >= 500
      InternalAsanaNotificationWorker.perform_async(
        name: "Order #{order.number} over $500 - #{order.user_name}",
        notes: "Order with suppliers #{order.suppliers.map(&:name).join(', ')} surpassed $500.\n\nOrder: #{ENV['ADMIN_SERVER_URL']}/admin/fulfillment/orders/#{order.number}/edit",
        projects: [AsanaService::OVER_500_PID]
      )
    end

    # [TECH-3398] Asana alert for $50+ orders from possible corporate users
    InternalNotificationService.notify_order_is_corporate(order) if order.taxed_total >= 50 && order.corporate? && !order.user_tagged_corporate? && order.first_corporate_order_from_user?

    # [TECH-3716] Asana alert for specific address of person we don't want to sell products
    InternalNotificationService.notify_order_address_is_blacklisted(order) if order.ship_address&.blacklisted_by_alert?

    PostOrderEmail.active.joins(:tag).merge(order.product_grouping_tags).pluck(:id).each do |id|
      UserPostOrderMailWorker.perform_async(order.id, id)
    end

    each_charge_gid_for(order.verifying_transition) do |charge_gid|
      CaptureChargeWorker.perform_async(charge_gid)
    end

    Order::FireSegmentEventsService.call(order: order)
    Order::UpdateGiftCardUsageWorker.perform_in(5.minutes, order.id)
    ScheduleShipmentsByOrderWorker.perform_async(order.id)
  rescue StandardError => e
    notify_sentry_and_log(e, "Exception on order listener. order_paid returned: #{e}")
  end

  def coupon_has_debit?(order)
    order.coupon_balance_adjustments.debit.present?
  end

  def order_canceled(order)
    Order::CancelShipmentsWorker.perform_async(order.id)
    YotpoService.new.cancel_order(order.id) if order.confirmed_at? && order.minibar?
    SegmentOrderCancelledWorker.perform_async(order.id)
    Coupon::GiftCardRefundWorker.perform_async(order.id) if order.all_gift_card_coupons.any?
    SendGiftOrderCancelledWorker.perform_async(order.id) if order.gift_detail.present?
    # TECH-4262 some orders are failing to refund if they were confirmed (settling)
    # and then canceled before the transaction was settled
    # So, fix: waiting 30 mins for transaction to settle and try to cancel if it hasn't been canceled
    Order::LateRefundWorker.perform_in(30.minutes, order.id) if order.confirmed_at.present?
  end

  def order_verifying(order)
    Order::VerifyWorker.perform_async(order.id)
  end

  # We process referrals 4 hours after an order has been confirmed, this allows
  # for the order to be confirmed and delivered. Currently we don't handle the
  # case where it is a scheduled order for delivery beyond 4 hours.
  # TODO: Moved to .order_paid when we add Order#fraud_checking state.
  def order_confirmed(order)
    Order::CreateYotpoOrderWorker.perform_async(order.id) if order.eligible_for_yotpo_review?
    ReferralCreditWorker.perform_in(4.hours, order.id)
    Order::UpdateGiftCardUsageWorker.perform_in(5.minutes, order.id)
    Order::ApproveCustomGiftCardImagesWorker.perform_async(order.id) if order.contains_digital_shipments?
  end

  def order_delivered(order)
    Order::SendOrderFulfilledEventWorker.perform_async(order.id)
  end

  def order_finalizing(order)
    Order::SendOrderFinalizedEventWorker.perform_async(order.id)
  end

  def order_placed(order)
    Order::SendOrderCreatedEventWorker.perform_async(order.id) if order.all_shipments_pre_sale_or_back_order?
  end

  private

  def each_charge_gid_for(transition, &block)
    Array(transition&.metadata&.fetch('charges', nil)).each(&block)
  end
end
