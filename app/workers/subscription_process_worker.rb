class SubscriptionProcessWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: 1,
                  queue: 'urgent',
                  lock: :until_and_while_executing

  def perform_with_error_handling
    SubscriptionService.new.process!
  end
end
