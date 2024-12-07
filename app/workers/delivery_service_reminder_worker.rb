class DeliveryServiceReminderWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal'

  # Triggered on shipment_paid
  # Note: Delivery service order gets created on shipment_confirmed
  def perform_with_error_handling(shipment_id, scheduled, minutes)
    shipment = Shipment.find(shipment_id)
    delivery_service = shipment.supplier&.delivery_service
    delivery_service_order = shipment.delivery_service_order

    # Should pass:
    # Shipments still in paid or confirmed
    #   That don't have a delivery service order (has not been confirmed) OR
    #   That have a delivery service order but no driver information
    return if delivery_service.blank?
    return if shipment.pickup?
    return if shipment.shipped?
    return if shipment.en_route? || shipment.delivered? || shipment.canceled?
    return if delivery_service_order.present? && !(delivery_service_order.dig('driver', 'driver_name').blank? &&
                                                   delivery_service_order.dig('driver', 'first_name').blank? &&
                                                   delivery_service_order.dig('courier', 'name').blank?)
    # TECH-4261 edge case, store has dsp flipper AND no delivery service AND it's confirmed
    return if shipment.confirmed? && delivery_service_order.blank? && shipment.show_dsp_flipper

    if shipment.scheduled_for.present? && !(shipment.scheduled_for >= 30.minutes.ago && shipment.scheduled_for <= Time.zone.now)
      # TECH-4261, comment: https://minibar.atlassian.net/browse/TECH-4261?focusedCommentId=41212
      # A shipment can be placed and then scheduled, in that case we schedule a new job (shipment.set_scheduled_reminders)
      # and then we return here (stop exec).
      # The only way we can allow the scheduled event continue in this job is that the scheduled_for is
      # between 30.minutes.ago and now.
      return
    end

    note = scheduled ? I18n.translate('notes.scheduled_delivery_service_reminder', minutes: minutes) : I18n.translate('notes.asap_delivery_service_reminder', minutes: minutes)
    user =  case delivery_service.name
            when 'DoorDash'
              RegisteredAccount.door_dash.user
            when 'CartWheel'
              RegisteredAccount.cart_wheel.user
            when 'DeliverySolutions'
              RegisteredAccount.delivery_solutions.user
            when 'Zifty'
              RegisteredAccount.zifty.user
            else
              RegisteredAccount.super_admin.user
            end
    shipment.comments.create(note: note, created_by: user&.id)
    InternalNotificationService.notify_30_min_passed_and_no_driver_picked(shipment)
  end
end
