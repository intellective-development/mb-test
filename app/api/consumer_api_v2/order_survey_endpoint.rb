class ConsumerAPIV2::OrderSurveyEndpoint < BaseAPIV2
  namespace :order_survey do
    route_param :order_survey_id do
      before do
        @survey = OrderSurvey.find_by(token: params[:order_survey_id])
        error!('Survey Not Found', 404) if @survey.nil?
      end

      desc 'Returns order survey', ConsumerAPIV2::DOC_AUTH_HEADER
      params do
        requires :order_survey_id, type: String
      end
      get do
        reasons = OrderSurveyReason.active.map { |r| r.attributes.slice('id', 'name') }

        # Scores may be set by an inbound link - eg. clicking a URL in an email.
        # Here we set the score, then create a background job to finalize the
        # survey after 10 minutes.
        if @survey && params[:score].present?
          @survey.update(score: params[:score])
          @survey.start
        end

        present :reasons, reasons
        present :survey, @survey, with: ConsumerAPIV2::Entities::Survey
      end

      desc 'Updates order survey', ConsumerAPIV2::DOC_AUTH_HEADER
      params do
        requires :score, type: String
        requires :comment, type: String
      end
      put do
        error!('Unable to update completed survey', 400) if @survey.state == 'completed'

        if params[:selected_reasons]
          OrderSurveyReason.where(id: params[:selected_reasons].map { |reason| reason['id'] }).each do |reason|
            @survey.order_survey_responses.create(order_survey_reason: reason)
          end
        end

        if @survey.update(score: params[:score], comment: params[:comment])
          @survey.complete
          present :survey, @survey, with: ConsumerAPIV2::Entities::Survey
        else
          error!('Unable to update survey', 400)
        end
      end
    end
  end
end
