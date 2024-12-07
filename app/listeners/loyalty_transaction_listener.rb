class LoyaltyTransactionListener < Minibar::Listener::Base
  subscribe_to Order, LoyaltyTransaction

  def order_paid(order)
    User::CreateLoyaltyTransactionWorker.perform_async(order.id) if LoyaltyProgramTester.loyalty_program_tester?(order.email)
  end

  def order_canceled(order)
    User::VoidLoyaltyTransactionWorker.perform_async(order.id) if order.loyalty_transaction
  end

  def loyalty_transaction_finalized(loyalty_transaction)
    CustomerNotifier.loyalty_reward(loyalty_transaction.user_id).deliver_later if loyalty_transaction.user.earned_loyalty_reward? && loyalty_transaction.user.account.storefront.default_storefront?
  end
end
