class UserPostOrderMailWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'notifications_customer',
                  lock: :until_and_while_executing

  def perform_with_error_handling(order_id, post_order_email_id)
    CustomerNotifier.post_order_email(order_id, post_order_email_id).deliver_now
  end
end
