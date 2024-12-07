class LoyaltyTransactionStateMachine
  include Statesman::Machine

  state :pending, initial: true # Loyalty Transactin in pending state for 6 hours from creation.
  state :finalized              # Loyalty Transaction has not been canceled within 6 hours of creation.
  state :voided                 # Loyalty Transaction has been canceled within 6 hours of creation.

  transition from: :pending, to: %i[finalized voided]

  guard_transition(to: :finalized) do |transaction|
    !transaction.order.canceled?
  end

  after_transition after_commit: true do |object, transition|
    object.broadcast_event(transition.to_state, prefix: true)
  end
end
