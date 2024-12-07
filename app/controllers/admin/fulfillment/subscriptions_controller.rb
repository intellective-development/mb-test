class Admin::Fulfillment::SubscriptionsController < Admin::Fulfillment::BaseController
  def index
    @subscriptions = Subscription.filter(params)
                                 .includes(:user, :base_order, :last_order)
                                 .order([state: :asc, created_at: :desc])
                                 .page(params[:page] || 1)
                                 .per(20)
  end

  def toggle_state
    subscription = Subscription.find(params[:id])
    subscription.active? ? subscription.deactivate : subscription.activate

    redirect_to admin_fulfillment_subscriptions_path
  end

  def schedule_next
    subscription = Subscription.find(params[:id])
    time = Time.zone.parse(params[:next_order_date])
    if subscription.active? && time.future?
      subscription.update(next_order_date: time)
      flash[:notice] = "Next Order Scheduled for #{subscription.next_order_date.strftime('%D %R')}"
    else
      flash[:error] = 'Sorry, this subscription cannot be scheduled.'
    end
    redirect_to admin_fulfillment_subscriptions_path
  end
end
