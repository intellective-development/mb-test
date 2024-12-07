class InventoryProductUpdateJob
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'inventory_product_updates',
                  lock: :until_and_while_executing,
                  unique_args: :unique_args

  sidekiq_throttle(concurrency: { limit: -> { peak_hours? ? 15 : 30 } },
                   threshold: { limit: 10_000, period: -> { peak_hours? ? 60.seconds : 30.seconds } })

  def perform_with_error_handling(data, supplier_id, options)
    InventoryProductUpdateService.new(data, supplier_id, options).process!
  rescue StandardError => e
    Rails.logger.info "Error on InventoryProductUpdateJob: #{e}"
    raise e
  end

  # TODO: Do we want to consider adding price/inventory here? Or do we assume that jobs are
  # always process before another is enqueued?
  def self.unique_args(args)
    [args[0]['sku'], args[1]]
  end
end
