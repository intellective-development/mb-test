class ChargeSettlementWorker
  include Sidekiq::Worker
  include WorkerErrorHandling
  include SentryNotifiable

  sidekiq_options retry: true,
                  queue: 'internal',
                  lock: :until_executing

  def perform_with_error_handling(charge)
    return true if charge.voided? || charge.settled?

    case String(charge.transaction_status)
    when 'submitted_for_settlement'
      raise RetryableException, "ChargeSettlementWorker: Charge #{charge.id} is still in submitted_for_settlement state"
    when 'voided'
      # TODO: JM: Not sure this is the right thing to do or not. We have some transactions
      # get voided, but the charge hasn't yet transitioned. We should not need this, should
      # just be able to return true and assume that void! did its thing.
      charge.reload
      charge.transition_to!(:voided, charge.transaction_metadata) unless charge.voided?
    when *PaymentGateway::SETTLED_STATUS
      charge.transition_to!(:settled, charge.transaction_metadata)
    else
      raise_sentry_message(charge)
    end
  rescue *PaymentGateway::TransactionalBase::RETRYABLES => e
    notify_sentry_and_log(e)
    raise e
  rescue StandardError => e
    notify_sentry_and_log(e)
  end

  private

  def raise_sentry_message(charge)
    message = "ChargeSettlementWorker: Unexpected settlement state for charge id: #{charge.id}"
    attributes = {
      user: { id: charge.user&.id },
      level: 'error',
      extra: {
        charge_state: charge.current_state,
        transaction_status: charge.transaction_status,
        shipment_id: charge.shipment&.id,
        order_number: charge.order&.number,
        order_id: charge.order&.id,
        payment_profile_id: charge.payment_profile&.id
      }
    }

    Sentry.capture_message(message, attributes)
  end
end
