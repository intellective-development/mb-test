class LoyaltyTransactionAwardWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'internal'

  def perform_with_error_handling(id)
    loyalty_transaction = LoyaltyTransaction.find(id)
    loyalty_transaction.transition_to(:finalized) if loyalty_transaction.can_transition_to?(:finalized)
  end
end
