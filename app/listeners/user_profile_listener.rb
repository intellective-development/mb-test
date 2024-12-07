class UserProfileListener < Minibar::Listener::Base
  subscribe_to Order

  # Updates personalization and external profiles once the order gets paid.
  def order_paid(order)
    UserProfileDeltaUpdateWorker.perform_async(order.user_id, order.id)
    UserOneSignalProfileUpdateWorker.perform_in(30.minutes, order.user_id)

    UserMailchimpProfileUpdateWorker.perform_in(30.minutes, order.user_id) unless ENV['MAILCHIMP_STATUS'] == 'DISABLED' || order.user.partner_api_user?
    SegmentUserUpdaterWorker.perform_in(1.minute, order.user_id)
    KustomerUserUpdaterWorker.perform_in(1.minute, order.user_id)
  end
end
