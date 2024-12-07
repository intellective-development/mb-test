class UserCartAbandonmentMailWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: false,
                  queue: 'notifications_customer'

  def perform_with_error_handling
    CartAbandonmentView.eligible_to_notify.each do |abandonment|
      next unless Feature[:cart_abandonment].enabled?(abandonment.user)

      abandonment.mark_user_notified_today
      order = abandonment.order
      cart_share = CartShare.create_from_order(order)
      CustomerNotifier.cart_abandonment(order.id, cart_share.id).deliver_now if cart_share
    end
  end
end
