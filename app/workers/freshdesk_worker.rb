class FreshdeskWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'notifications_internal'

  def perform_with_error_handling(params)
    FreshdeskService.new.create_ticket(params) if ENV['FRESHDESK_URL']
  end
end
