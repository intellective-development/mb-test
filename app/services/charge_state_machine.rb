class ChargeStateMachine
  extend PaymentGateway::TransactionMethods::ClassMethods
  include Statesman::Machine
  include SentryNotifiable

  state :pending, initial: true # Not yet attempted authorization
  state :authorized             # Braintree 'Authorized' state
  state :declined               # Braintree 'Declined'
  state :failed                 # Braintree 'Error: failed', 'Gateway rejected'
  state :voided                 # Braintree 'Voided'
  state :settling               # Braintree 'Submitted for settlement'
  state :settled                # Braintree 'Settled'
  state :settlement_declined    # Braintree 'Settlement_declined'
  state :refunded               # Braintree 'Refunded'

  transition from: :pending,    to: %i[authorized declined failed settling]
  transition from: :authorized, to: %i[voided settling]
  transition from: :settling,   to: %i[settled voided refunded settlement_declined]
  transition from: :settled,    to: [:refunded]

  # These use GlobalID to Serialize / Deserialize the object.
  after_transition(to: :settling) do |charge|
    SettleChargeJob.set(wait: 1.minute).perform_later(charge)
  end

  after_transition(to: :settled) do |charge|
    charge.broadcast_event(:settled, prefix: true)
  end

  after_transition do |charge, transition|
    trigger_fraud_transaction_event(charge)
    MetricsClient::Metric.emit("minibar_web.state_machine.charge.transition.to.#{transition.to_state}", 1)
  end

  # These guards ensure that we don't change state without accompanying
  # proof that the transaction is actually in an appropriate state.
  #
  # To achieve this the transition_to method must be preceded by
  # a call to the action that accompanies the transition state.
  # For example to transition to 'voided'
  #
  #   cancellation = PaymentGateway::Void.new(transaction_id)
  #   transition_to!(:voided, cancellation.metadata) if cancellation.process
  #
  # The guard then validates the status of the transaction from the metadata.
  # This has a secondary effect of ensuring we always pass the metadata to be
  # stored in the ChargeStateTransition, therefore providing an audit log.
  guard_transition(to: :authorized) do |_charge, _transition, metadata|
    assert_metadata_status(metadata, 'authorized')
  end

  guard_transition(to: :declined) do |_charge, _transition, metadata|
    assert_metadata_status(metadata, 'processor_declined')
  end

  guard_transition(to: :settling) do |_charge, _transition, metadata|
    assert_metadata_status(metadata, %w[submitted_for_settlement settling])
  end

  guard_transition(to: :voided) do |_charge, _transition, metadata|
    assert_metadata_status(metadata, 'voided')
  end

  guard_transition(to: :failed) do |_charge, _transition, metadata|
    metadata.key?(:errors)
  end

  guard_transition(to: :settled) do |charge, _transition, _metadata|
    consider_settled?(charge.transaction_status)
  end

  guard_transition(to: :settlement_declined) do |_charge, _transition, metadata|
    assert_metadata_status(metadata, 'settlement_declined')
  end

  guard_transition(to: :refunded) do |_charge, _transition, metadata|
    assert_metadata_status(metadata, %w[submitted_for_settlement settling]) && metadata[:type] == 'credit'
  end

  #----------------------------------------
  # Class methods
  #----------------------------------------
  def self.assert_metadata_status(metadata, expected_statuses)
    expected_statuses = [expected_statuses] if expected_statuses.is_a?(String)
    return true if expected_statuses.include?(metadata[:status])

    Rails.logger.warn("ChargeTransition guard failure: mismatch in metadata status. metadata: #{metadata}; xpected_status: #{expected_statuses.join(' or ')}")
    false
  end

  def self.trigger_fraud_transaction_event(charge)
    # Skip when it's not credit card (Paypal and Apple)
    Fraud::TransactionEvent.new(charge).call_async if charge.chargeable&.payment_profile&.credit_card?
  end

  #----------------------------------------
  # Instance methods
  #----------------------------------------
  def consider_settled?
    self.class.consider_settled?(current_state)
  end
end
