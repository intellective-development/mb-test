class Account::SubscriptionsController < Account::BaseController
  layout 'minibar'

  def index
    @subscriptions = current_user.subscriptions
                                 .page(params[:page])
                                 .per(20)
  end

  def show
    @subscriptions = current_user.subscriptions
                                 .find_by(number: params[:id])
  end

  def toggle
    subscription = current_user.subscriptions.find(params[:id])
    subscription.active? ? subscription.deactivate : subscription.activate

    redirect_to account_subscriptions_path
  end
end
