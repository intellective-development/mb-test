class Order::SurveyWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'internal',
                  lock: :until_and_while_executing

  def perform_with_error_handling(order_id)
    Order.find(order_id).tap do |order|
      return unless order.eligible_for_order_survey? # rubocop:disable Lint/NonLocalExitFromIterator

      OrderSurvey.prepare(order)
      CustomerNotifier.order_survey(order.id).deliver_now if Feature[:order_surveys].enabled?(order.user)
    end
  end
end
