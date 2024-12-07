class SiftDecisionWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'high_priority',
                  lock: :until_executing

  def perform_with_error_handling(options)
    Fraud::Decision.new(options).call
  end
end
