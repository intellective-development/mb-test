class OrderSurveyListener < Minibar::Listener::Base
  subscribe_to Order, OrderSurvey

  # After a pre-set delay we create an order survey for the customer. This will
  # be displayed in the app or on the website.
  def order_confirmed(order)
    Order::SurveyWorker.perform_at(OrderSurvey.survey_time(order), order.id)
  end

  def order_survey_started(order_survey)
    OrderSurveyFinalizationWorker.perform_in(10.minutes, order_survey.id)
  end

  def order_survey_completed(order_survey)
    # Update our supplier scores
    order_survey.suppliers.each do |supplier|
      SupplierScoreUpdateWorker.perform_async(supplier.id)
    end

    if order_survey.eligible_for_app_review?
      delay_timezoned = (order_survey.order.created_at + Settings.app_review_prompt_delay.days).in_time_zone(order_survey.order.shipments.first.supplier.timezone)
      hour_of_day_delay_timezoned = delay_timezoned.at_beginning_of_day.advance(hours: Settings.app_review_prompt_hour_of_day)
      UserAppReviewMailWorker.perform_at(hour_of_day_delay_timezoned, order_survey.id)
    end

    # Escalate if appropriate
    FreshdeskWorker.perform_async(order_survey.freshdesk_params) if order_survey.escalate?
  end
end
