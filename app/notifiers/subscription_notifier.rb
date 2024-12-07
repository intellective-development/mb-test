class SubscriptionNotifier < BaseNotifier
  helper :customer_notifier

  def subscription_activated(subscription_id)
    @subscription = Subscription.includes(:user)
                                .find(subscription_id)
    return unless @subscription.user.minibar?

    mail(to: @subscription.user.email_address_with_name, subject: format_subject('Welcome to Auto-Refill!')) do |format|
      format.html { render layout: 'email_ink' }
    end
  end

  def subscription_deactivated(subscription_id)
    @subscription = Subscription.includes(:user)
                                .find(subscription_id)
    return unless @subscription.user.minibar?

    mail(to: @subscription.user.email_address_with_name, subject: format_subject('We\'ve Suspended Your Subscription')) do |format|
      format.html { render layout: 'email_ink' }
    end
  end

  def subscription_reminder(subscription_id)
    @subscription = Subscription.includes(:user, :base_order)
                                .find(subscription_id)
    return unless @subscription.user.minibar?

    @order        = @subscription.base_order

    # In case the subscription has been cancelled between scheduling this
    # notification and now.
    return unless @subscription.active?

    mail(to: @subscription.user.email_address_with_name, subject: format_subject('Your Minibar Delivery Is Tomorrow!')) do |format|
      format.html { render layout: 'email_ink' }
    end
  end

  def subscription_failure(subscription_id)
    @subscription = Subscription.includes(:user, :base_order)
                                .find(subscription_id)
    return unless @subscription.user.minibar?

    @order        = @subscription.base_order

    mail(to: @subscription.user.email_address_with_name, subject: format_subject("Your Minibar Subscription Order couldn't be processed")) do |format|
      format.html { render layout: 'email_ink' }
    end
  end
end
