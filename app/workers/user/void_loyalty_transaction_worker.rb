class User::VoidLoyaltyTransactionWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_and_while_executing

  def perform_with_error_handling(order_id)
    LoyaltyTransaction.in_state('pending').find_by(order_id: order_id)&.transition_to!(:voided)
  end
end
