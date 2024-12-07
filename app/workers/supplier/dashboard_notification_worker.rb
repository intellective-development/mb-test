class Supplier::DashboardNotificationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'urgent',
                  lock: :until_and_while_executing

  def perform_with_error_handling(order_id)
    order = Order.includes(:shipments).find(order_id)
    order.shipments.find_each(&:notify_supplier_dash)
  end
end
