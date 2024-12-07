class InternalAsanaNotificationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: 3,
                  lock: :until_expired,
                  lock_ttl: 10.minutes,
                  queue: 'notifications_internal'

  def perform_with_error_handling(params)
    rate_limit = Sidekiq::Limiter.window('asana-api-rate-limit',
                                         1000,
                                         :minute,
                                         {
                                           # stay in busy wait for up to 2 minutes. this helps to avoid more work
                                           # to be picked up. we already reached max rate, so its pointless to schedule
                                           # new work, lets just wait a bit more. also we need to avoid raising
                                           # exceptions as we only do 3 attempts
                                           wait_timeout: 2.minutes,

                                           # backoff to a minute + rand(600)s + 1 - bigger rand ensures bigger
                                           # spread part for better change to get a window outside initial part
                                           # of the hour when running backfills
                                           backoff: lambda do |_limiter, job, _exception|
                                             (120 * job['overrated']) + rand(500) + 1
                                           end
                                         })

    rate_limit.within_limit do
      MetricsClient::Metric.emit("minibar.workers.#{self.class.name.downcase}.sent", 1)

      begin
        Slack::PostAsanaTaskOnSlack.new.call(params) if Feature[:asana_to_slack].enabled?
      rescue StandardError => e
        Rails.logger.error "InternalAsanaNotificationWorker: #{e}"
      end

      AsanaService.new.create_task(params)
    end
  end
end
