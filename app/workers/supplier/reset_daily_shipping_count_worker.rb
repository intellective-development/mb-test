class Supplier::ResetDailyShippingCountWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'internal',
                  lock: :until_and_while_executing

  def perform_with_error_handling
    Supplier.update_all(daily_shipping_count: 0)
  end
end
