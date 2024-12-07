class MinibarDashboardNotificationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  REDIS_PREFIX = 'SupplierDashboardNotificationWorker'.freeze

  sidekiq_options retry: true,
                  queue: 'notifications_supplier',
                  lock: :until_and_while_executing

  # Acceptable types - fetch|comment|adjustment
  def perform_with_error_handling(shipment_id, notification_type = 'fetch')
    shipment = Shipment.find(shipment_id)
    return if shipment.supplier&.dashboard_type != Supplier::DashboardType::MINIBAR
    return if shipment.order&.verifying?

    shipment.receipt_url if instant_receipt_activated?(shipment.supplier_id)
    service = EntityNotificationService.new(shipment, notification_type)
    service.call
  end

  private

  def instant_receipt_activated?(supplier_id)
    # Activate suppliers with: Redis.current&.sadd("SupplierDashboardNotificationWorker:instant_receipt_activated_suppliers", supplier_id)
    Redis.current&.sismember("#{REDIS_PREFIX}:instant_receipt_activated_suppliers", supplier_id)
  end
end
