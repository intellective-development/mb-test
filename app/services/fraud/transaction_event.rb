module Fraud
  class TransactionEvent < Event
    extend Forwardable
    def_delegator :transaction_details, :[], :transaction

    def initialize(charge)
      @charge = charge
      user = @charge&.order&.user
      application_id = @charge&.order&.doorkeeper_application_id
      access_token = user&.latest_doorkeeper_access_token(application_id)&.token
      session = Struct.new(:id).new(access_token)
      super(user, session, nil)
    end

    def self.event_type
      '$transaction'
    end

    def properties
      super.merge(
        '$amount' => currency_amount(@charge&.amount),
        '$currency_code' => 'USD',
        '$user_email' => user_email,
        '$transaction_type' => transaction(@charge&.current_state)&.type,
        '$transaction_status' => transaction(@charge&.current_state)&.status,
        '$order_id' => @charge&.order&.number,
        '$transaction_id' => @charge&.transaction_id,
        '$billing_address' => address_properties(@charge&.order&.bill_address),
        '$payment_method' => payment_profile_properties(@charge&.order&.payment_profile),
        '$shipping_address' => address_properties(@charge&.order&.ship_address),
        '$seller_user_id' => @charge&.supplier&.permalink,
        'channel' => @charge&.order&.doorkeeper_application_name
        # "$session_id"       => "gigtleqddo84l8cm15qe4il"
      )
    end

    def user_email
      return @charge&.order&.email if @user.present? && @user.account.present? && @user.guest_by_email?

      @user&.email
    end

    def transaction_details
      @transaction_details ||= {
        'authorized' => TransactionDetail.new('$authorize', '$success'), # Braintree 'Authorized' state
        'declined' => TransactionDetail.new('$authorize', '$failure'), # Braintree 'Declined'
        'failed' => TransactionDetail.new('$authorize', '$failure'), # Braintree 'Error: failed', 'Gateway rejected'
        'voided' => TransactionDetail.new('$void', '$success'),      # Braintree 'Voided'
        'settling' => TransactionDetail.new('$capture', '$pending'), # Braintree 'Submitted for settlement'
        'settled' => TransactionDetail.new('$capture', '$success'), # Braintree 'Settled'
        'settlement_declined' => TransactionDetail.new('$capture', '$failure'), # Braintree 'Settlement_declined'
        'refunded' => TransactionDetail.new('$refund', '$success')     # Braintree 'Refunded'
      }
    end
  end

  TransactionDetail = Struct.new(:type, :status)
end
