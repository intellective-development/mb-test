##
# This job is used to cache the supplier data in the database
#
class SupplierCacheJob
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal',
                  retry: false,
                  lock: :until_and_while_executing

  def perform_with_error_handling
    start_time = Time.new.to_i
    date_time = DateTime.now - 30.minutes

    supplier_ids = Variant.where('updated_at > ? or deleted_at > ?', date_time, date_time)
                          .select(:supplier_id)
                          .distinct
                          .pluck(:supplier_id)

    return if supplier_ids.blank?

    Supplier.where(id: supplier_ids).map(&:touch)

    MetricsClient::Metric.emit('supplier_cache.perform.duration', Time.new.to_i - start_time)
    MetricsClient::Metric.emit('supplier_cache.perform.updated_suppliers', supplier_ids.count)
  end
end
