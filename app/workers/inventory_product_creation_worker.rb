class InventoryProductCreationWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'inventory_product_creation',
                  lock: :until_and_while_executing

  # TODO: Can we dynamically throttle this based on Apdex or something?
  sidekiq_throttle(concurrency: { limit: -> { peak_hours? ? 1 : 2 } },
                   threshold: { limit: 10, period: -> { peak_hours? ? 300.seconds : 30.seconds } })

  def perform_with_error_handling(data, supplier_id, options)
    InventoryProductCreationService.new(data, supplier_id, options).process!
  end

  private

  def peak_hours?
    Time.zone.now.hour > 13
  end
end
