class ConsumerAPIV2::SubscriptionsEndpoint < BaseAPIV2
  helpers do
  end

  before do
    authenticate!
    validate_device_udid!
  end

  # Routes
  namespace :subscription do
    route_param :id do
      before do
        @subscription = @user.subscriptions.find(params[:id])
        error!('Invalid Subscription ID', 400) if @subscription.nil?
        Sentry.set_extras(subscription: { id: @subscription.id })
      end

      namespace :actions do
        desc 'Resume a subscription', ConsumerAPIV2::DOC_AUTH_HEADER
        post :activate do
          @subscription.activate

          status 200
          present @subscription, with: ConsumerAPIV2::Entities::Subscription
        end

        desc 'Suspend a subscription', ConsumerAPIV2::DOC_AUTH_HEADER
        post :deactivate do
          @subscription.deactivate

          status 200
          present @subscription, with: ConsumerAPIV2::Entities::Subscription
        end
      end
    end
  end

  namespace :subscriptions do
    desc 'Retrives a list of the customers subscriptions', ConsumerAPIV2::DOC_AUTH_HEADER
    params do
      optional :page,     type: Integer, desc: '', minimum_value: 1, default: 1
      optional :per_page, type: Integer, desc: '', maximum_value: 10, default: 8
    end
    get do
      @subscriptions = @user.subscriptions.order(:next_order_date).page(params[:page]).per(params[:per_page])

      status 200
      present @subscriptions, with: ConsumerAPIV2::Entities::Subscription
    end
  end
end
