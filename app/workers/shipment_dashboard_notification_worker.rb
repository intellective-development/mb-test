class ShipmentDashboardNotificationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'notifications_shipment',
                  lock: :until_executed,
                  unique: :until_and_while_executing,
                  on_conflict: :reject

  def perform_with_error_handling(id, state = nil)
    shipment = Shipment.find(id)
    return if shipment.supplier.dashboard_type == Supplier::DashboardType::MINIBAR

    raise WorkerException::RetryableException, "[ShipmentDashboardNotification] order is still being verified for shipment ##{id}" if shipment.order.verifying?

    raise StandardError, "[ShipmentDashboardNotification] order is not considered paid for shipment ##{id}" if !shipment.order.consider_paid? && shipment.customer_placement_standard?

    return if shipment.suspected_fraud? && !cancel_non_standard_shipment?(shipment, state)

    Dashboard::DashboardService.notify(shipment, state)
  rescue StandardError => e
    Rails.logger.info(e.message)
    raise e
  end

  private

  def cancel_non_standard_shipment?(shipment, state)
    !shipment.customer_placement_standard? && state == 'canceled'
  end
end
