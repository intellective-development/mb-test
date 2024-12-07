# frozen_string_literal: true

# Worker to move shipments from paid to scheduled when the scheduled_for time has passed.
# It will also trigger the schedule event on the order if all shipments are scheduled.
class ScheduleShipmentsByOrderWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal',
                  lock: :until_executed

  def perform_with_error_handling(order_id)
    order = Order.includes(:shipments).find(order_id)
    shipments_to_schedule = order.shipments
                                 .in_state(:paid)
                                 .joins(:supplier)
                                 .where(order_id: order_id, suppliers: { dashboard_type: Supplier::DashboardType::SPECS })
                                 .where.not(scheduled_for: nil)
    shipments_to_schedule.each(&:schedule!)

    order.trigger!(:schedule) if order.shipments.all?(&:scheduled?)
  end
end
