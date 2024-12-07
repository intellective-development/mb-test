module AccountHelper
  def subscription_toggle_label(subscription)
    subscription.active? ? 'Suspend' : 'Reactivate'
  end

  def subscription_toggle_warning(subscription)
    subscription.active? ? 'Please confirm that you would like to cancel your subscription. You can reactivate at any time.' : "Please confirm that you would like to reactivate your subscription. The next delivery will be in #{subscription.interval} days."
  end

  def display_completed_at(order)
    return I18n.localize(order.completed_at, format: '%m/%d/%Y @ %I:%M %p %Z') if order.completed_at

    return 'Processing' if order.finalizing?

    'Not Finished.'
  end
end
