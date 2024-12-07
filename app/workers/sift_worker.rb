class SiftWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'high_priority',
                  lock: :until_executing

  def perform_with_error_handling(event_type, properties)
    Fraud::Event.new(nil, nil, nil, event_type, properties).call
  end
end
