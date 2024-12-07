class PrizeLogicNotificationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'notifications_customer'

  def perform_with_error_handling(one_time_code_id)
    CustomerNotifier.prize_logic(one_time_code_id).deliver_now
  end
end
