class User::CreateLoyaltyTransactionWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_and_while_executing

  def perform_with_error_handling(order_id)
    Order.find(order_id).tap do |order|
      LoyaltyTransaction.create!(order: order, user: order.user, points: 1) if LoyaltyProgramTester.exists?(email: order.email)
    end
  end
end
