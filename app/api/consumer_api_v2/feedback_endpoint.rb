class ConsumerAPIV2::FeedbackEndpoint < BaseAPIV2
  format :json

  resource :feedback do
    before do
      authenticate!
    end
    desc 'Returns Eligible Surveys', ConsumerAPIV2::DOC_AUTH_HEADER
    get do
      present :eligible, @user.order_surveys.pending, with: ConsumerAPIV2::Entities::OrderSurvey
      present :pending,  @user.orders.where('completed_at > ?', 12.hours.ago).count.positive?
    end
    params do
      requires :survey_token, type: String
      requires :rating,       type: Integer
      optional :comments,     type: String
    end
    post do
      @survey = OrderSurvey.pending.find_by(token: params[:survey_token])
      error!('Invalid Survey Token', 400) if @survey.nil?
      error!('Unauthorized', 403)         if @survey.user != @user

      @survey.score   = params[:rating]
      @survey.comment = params[:comments]

      if @survey.save
        @survey.complete!
        present :success, true
      end
    end
  end
end
