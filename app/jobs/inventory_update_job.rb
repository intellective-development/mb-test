class InventoryUpdateJob
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'inventory'

  sidekiq_throttle(concurrency: { limit: 2 },
                   threshold: { limit: 2, period: 1.minute })

  def perform_with_error_handling(params)
    InventoryUpdateService.new(params).process!
  end
end
