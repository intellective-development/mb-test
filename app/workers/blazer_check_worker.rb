class BlazerCheckWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'internal'

  def perform_with_error_handling(schedule)
    Blazer.run_checks(schedule: schedule)
  end
end
