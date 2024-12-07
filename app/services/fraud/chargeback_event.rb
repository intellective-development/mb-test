module Fraud
  class ChargebackEvent < Event
    def initialize(dispute)
      super(dispute.order.user, nil, nil)
      @dispute = dispute
      @order = dispute.order
    end

    def self.event_type
      '$chargeback'
    end

    # https://sift.com/developers/docs/ruby/events-api/reserved-events/chargeback
    SIFT_CHARGEBACK_REASONS = {
      'cancelled_recurring_transaction' => '$other',
      'credit_not_processed' => '$other',
      'duplicate' => '$duplicate',
      'fraud' => '$fraud',
      'general' => '$other',
      'invalid_account' => '$other',
      'not_recognized' => '$other',
      'product_not_received' => '$product_not_received',
      'product_unsatisfactory' => '$product_unacceptable',
      'transaction_amount_differs' => '$other'
    }.freeze

    SIFT_CHARGEBACK_STATES = {
      'open' => '$received',
      'lost' => '$lost',
      'won' => '$won'
    }.freeze

    def properties
      super.except('$browser').merge(
        '$order_id' => @order.number,
        '$transaction_id' => @dispute.transaction_id || @order.charges.first&.transaction_id,
        '$chargeback_state' => SIFT_CHARGEBACK_STATES[@dispute.status],
        '$chargeback_reason' => SIFT_CHARGEBACK_REASONS[@dispute.reason]
      )
    end
  end
end
