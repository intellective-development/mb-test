class OrderSurveyFinalizationWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'internal',
                  lock: :until_and_while_executing

  def perform_with_error_handling(order_survey_id)
    order_survey = OrderSurvey.started.find_by(id: order_survey_id)
    order_survey&.complete
  end
end
