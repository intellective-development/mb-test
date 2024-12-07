module PaymentGateway
  class Refund < TransactionalBase
    # 91512: Transaction has already been fully refunded
    # 4004: Settlement - Already Refunded
    ERROR_ALREADY_REFUNDED = %w[91512 4004].freeze

    def initialize(transaction_id, business, payment_type, amount = nil)
      super transaction_id, business, payment_type
      @amount = amount
    end

    def action
      gateway.transaction.refund(@transaction_id, @amount)
    end

    def already_refunded?
      @result.errors.any? { |error| ERROR_ALREADY_REFUNDED.include?(error.code.to_s) }
    rescue StandardError => e
      Rails.logger.error("Error checking if transaction was already refunded: #{e.message}")
      false
    end

    def success?
      if @result && !@success && already_refunded?
        Rails.logger.info("TransactionAlreadyRefunded: #{@transaction_id}")
        MetricsClient::Metric.emit('refund.error.transaction_already_refunded', 1)
        return true
      end

      @success
    end
  end
end
