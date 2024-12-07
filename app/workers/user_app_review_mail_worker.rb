class UserAppReviewMailWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'notifications_customer',
                  lock: :until_and_while_executing

  def perform_with_error_handling(order_survey_id)
    CustomerNotifier.prompt_app_review(order_survey_id).deliver_now if OrderSurvey.where(id: order_survey_id).any?
  end
end
