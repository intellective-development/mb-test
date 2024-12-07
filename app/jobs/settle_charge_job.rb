class SettleChargeJob < ActiveJob::Base
  include SentryNotifiable

  queue_as :internal

  def perform(charge)
    return true if charge.voided? || charge.settled?

    case String(charge.transaction_status)
    when 'submitted_for_settlement'
      retry_job wait: 15.minutes
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
    Rails.logger.warn("Retryable exception when settling charge: #{e}")
    raise e
  rescue StandardError => e
    notify_sentry_and_log(e, "Unretryable exception when settling charge: #{e}")
  end

  private

  def raise_sentry_message(charge)
    message = "SettleChargeJob: Unexpected settlement state for charge id: #{charge.id}"
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

    message_sentry_and_log(message, attributes)
  end
end
