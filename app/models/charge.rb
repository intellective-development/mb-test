# == Schema Information
#
# Table name: charges
#
#  id             :integer          not null, primary key
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  transaction_id :string(64)
#

class Charge < ApplicationRecord
  class InvalidStateError < StandardError
    def initialize(state)
      super "Can not cancel! when in #{state} state"
    end
  end

  class TransactionStatusError < StandardError
    def initialize(status)
      super "Can not cancel! when the transaction is #{status}"
    end
  end

  extend PaymentGateway::TransactionMethods::ClassMethods
  include Statesman::Adapters::ActiveRecordQueries
  include MachineAdapter

  statesman_machine machine_class: ChargeStateMachine, transition_class: ChargeTransition

  has_one :chargeable, inverse_of: :charge
  has_one :shipment, through: :chargeable
  has_one :last_shipment_charge, class_name: 'ShipmentCharge'
  has_one :order_adjustment
  has_one :last_charge_transition, -> { where(most_recent: true) }, class_name: 'ChargeTransition'
  has_many :charge_transitions, dependent: :destroy
  has_many :customer_refunds, dependent: :destroy

  delegate :amount, to: :chargeable, allow_nil: true
  delegate :status, to: :transaction, prefix: true, allow_nil: true
  delegate :metadata, to: :transaction, prefix: true, allow_nil: true
  delegate :consider_settled?, to: :transaction, allow_nil: true

  #--------------------------------------------------
  # Class methods
  #--------------------------------------------------

  def supplier
    chargeable&.supplier
  end

  #--------------------------------------------------
  # Instance methods
  #--------------------------------------------------
  def authorize!(**options)
    authorization_options[:options] = options

    authorization = PaymentGateway::Authorization.new(amount, card_token, merchant_account_id, business, payment_profile&.payment_type, authorization_options)

    # TODO: JM: If something raises in the gateway we need to do something about it.
    # I'm not sure what! authorization gives us a #failed? for failures.
    if authorization.process
      new_state = %w[submitted_for_settlement settling].include?(authorization.status) ? :settling : :authorized
      transition_to!(new_state, authorization.metadata)
    elsif authorization.declined? && can_be_declined?
      transition_to!(:declined, authorization.metadata)
    elsif authorization.declined?
      # ignore as this is already authorized (likely from a race between authorized and declined)
    else
      transition_to!(:failed, authorization.metadata)
    end

    self.transaction_id = authorization.transaction_id
    save!
  rescue Statesman::GuardFailedError => e
    transaction_id = authorization&.transaction_id
    update_attribute('transaction_id', transaction_id) if transaction_id

    notify_sentry_and_log(e, "Charge authorize transition error. #{e.class.name}",
                          { tags: { charge_id: id, transaction_id: transaction_id&.to_s, message: e.message } })
    raise e
  rescue StandardError => e
    notify_sentry_and_log(e, "Charge authorization error: #{e.class.name}. Here's the error message: #{e.message} and some useful data (charge_id: #{id}, transaction_id: #{authorization&.transaction_id}",
                          { tags: { charge_id: id, transaction_id: authorization&.transaction_id, message: e.message } })

    raise API::Errors::BrainTreeError
  end

  def cancel!
    raise InvalidStateError, current_state unless can_be_cancelled?

    case transaction_status
    when *PaymentGateway::VOIDABLE_STATUS then void!
    when *PaymentGateway::SETTLED_STATUS then refund!
    else raise TransactionStatusError, transaction_status
    end
  end

  def capture!
    capture = PaymentGateway::Capture.new(transaction_id, business, payment_profile&.payment_type)
    transition_to!(:settling, capture.metadata) if capture.process
  end

  def void!
    return false unless can_be_voided?

    void = PaymentGateway::Void.new(transaction_id, business, payment_profile&.payment_type)
    # TODO: JM: If we use this inline we should call void.process_or_retry
    # TODO: JM: Additionally we can send sentry errors for unexpected conditions
    # with refund.notify_sentry. I've not turned this on in the gateway but it works
    transition_to!(:voided, void.metadata) if void.process
  end

  def refund!(refund_amount = nil)
    return false unless settled? || can_be_settled?

    transition_to!(:settled, transaction_metadata) if can_be_settled?

    refund = PaymentGateway::Refund.new(transaction_id, business, payment_profile&.payment_type, refund_amount)
    # TODO: JM: If we use this inline we should call refund.process_or_retry
    if refund.process
      refund_metadata = refund.metadata
      refund_metadata['original_refund_amount'] = refund_amount # for debugging
      customer_refunds.build(amount: refund_metadata[:amount], transaction_id: refund_metadata[:id], metadata: refund_metadata)

      begin
        transition_to!(:refunded, refund_metadata) if balance.zero?
      rescue Statesman::GuardFailedError => e
        Rails.logger.error("Failed transition to refunded from #{current_state}: #{e.message}")
      end

      save!
    end
  end

  def can_be_settled?
    settling? && transaction.consider_settled?
  end

  def authorized_or_settling?
    authorized? || settling?
  end

  def consider_charged?
    %w[authorized settled settling].include?(current_state)
  end

  def can_be_cancelled?
    consider_charged?
  end

  def can_be_declined?
    %w[pending settled settling].include?(current_state)
  end

  def can_be_voided?
    authorized? || settling?
  end

  def transaction
    @transaction ||= PaymentGateway::Transaction.new(transaction_id, business, payment_profile&.payment_type) if transaction_id
  end

  def state_machine
    @state_machine ||= ChargeStateMachine.new(self, transition_class: ChargeTransition)
  end

  def order
    chargeable&.order
  end

  def payment_profile
    order&.payment_profile
  end

  def user
    order&.user
  end

  def business
    order&.storefront&.business
  end

  def merchant_account_id
    @merchant_account_id ||= chargeable.supplier.get_braintree_merchant_account_id
  end

  def card_token
    @card_token ||= chargeable.payment_profile.braintree_token
  end

  def balance?
    balance.positive?
  end

  # Subtract all refund amounts from original amount.
  def balance
    return 0.0 unless settled? || settling?

    refunded_amount = all_refunds.map(&:amount).inject(BigDecimal('0.0'), :+)
    amount - refunded_amount
  end

  # merged array of persisted and unpersisted refunds. Lazy means we
  # only iterate over the array once for all the chained methods.
  def all_refunds
    customer_refunds.load_target.lazy
  end

  # The unique_id is the global_id for the shipment. It gets turned into order_id in Braintree
  # and will stop false duplicates as the shipment global_id should be unique.
  def unique_id
    @unique_id ||= if shipment
                     shipment.to_global_id.to_param
                   else
                     order.to_global_id.to_param
                   end
  end

  def partner_options
    partner_options = {}

    if shipment&.supplier&.dashboard_type == Supplier::DashboardType::SEVEN_ELEVEN
      # this must match amounts in SevenElevenDashboard::create_payment_details_object but we can't access amounts here
      total_amount = shipment&.total_before_discounts.to_f || 0
      gift_card_amount = shipment&.gift_card_amount.to_f || 0
      promo_amount = (shipment&.discounts_total.to_f - gift_card_amount).round(2)

      partner_options = {
        partner_store_id: shipment&.supplier&.external_supplier_id,
        partner_total_amount: total_amount,
        partner_gift_card_amount: gift_card_amount,
        partner_promo_amount: promo_amount
      }
    end

    if shipment&.supplier&.dashboard_type == Supplier::DashboardType::SPECS
      partner_options = {
        partner_store_id: shipment&.supplier&.external_supplier_id
      }
    end

    partner_options
  end

  def authorization_options
    @authorization_options ||= {
      unique_id: unique_id,
      order_id: order.id,
      shipment_id: shipment&.id,
      payment_profile_id: order.payment_profile_id,
      payment_type: order.payment_profile&.payment_type,
      user_id: order.user_id,
      business_name: order.storefront&.business&.name,
      order_number: order.number,
      **partner_options
    }
  end
end
