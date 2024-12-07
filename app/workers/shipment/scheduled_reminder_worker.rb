class Shipment::ScheduledReminderWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: 5,
                  queue: 'internal'

  def perform_with_error_handling(shipment_id)
    Shipment.scheduled.future.on_demand.find_by(id: shipment_id)&.tap do |shipment|
      if shipment.scheduled_for.today?
        ShipmentDashboardNotificationWorker.perform_async(shipment_id)

        # Making sure we don't send one of these for each shipment.
        CustomerNotifier.scheduled_order_reminder(shipment.order_id).deliver_later if shipment.first_for_order?
      else
        # Order has been rescheduled and reminder is no longer valid
        shipment.set_scheduled_reminders
      end
    end
  end
end
