class DataFeedWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker
  include WorkerErrorHandling
  include SentryNotifiable

  sidekiq_options retry: 2,
                  queue: 'inventory',
                  lock: :until_and_while_executing

  sidekiq_throttle(concurrency: { limit: 1 })

  def perform_with_error_handling(feed_id, force = false)
    feed = DataFeed.find(feed_id)
    feed.clear_digest if force
    feed.fetch if feed.active?
  rescue StandardError => e
    notify_sentry_and_log(e, "Error fetching feed #{feed_id} (#{feed.supplier.name}): #{e}")
  end
end
