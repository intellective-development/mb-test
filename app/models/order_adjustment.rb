# == Schema Information
#
# Table name: chargeables
#
#  id              :integer          not null, primary key
#  braintree       :boolean          default(TRUE), not null
#  credit          :boolean
#  reason_id       :integer
#  shipment_id     :integer
#  user_id         :integer
#  description     :text
#  created_at      :datetime
#  updated_at      :datetime
#  amount          :decimal(, )
#  processed       :boolean          default(FALSE), not null
#  financial       :boolean          default(TRUE), not null
#  line_item_id    :integer
#  type            :string(64)       not null
#  charge_id       :integer
#  substitution_id :integer
#  adjustment_type :integer
#  order_id        :integer
#  supplier_id     :integer
#  taxes           :boolean
#
# Indexes
#
#  chargeables_order_id_idx              (order_id)
#  index_chargeables_on_adjustment_type  (adjustment_type)
#  index_chargeables_on_charge_id        (charge_id)
#  index_chargeables_on_line_item_id     (line_item_id)
#  index_chargeables_on_shipment_id      (shipment_id)
#  index_chargeables_on_type_and_id      (type,id)
#

#  ____                                 _____ _______ _____
# |  _ \                               / ____|__   __|_   _|
# | |_) | _____      ____ _ _ __ ___  | (___    | |    | |
# |  _ < / _ \ \ /\ / / _` | '__/ _ \  \___ \   | |    | |
# | |_) |  __/\ V  V / (_| | | |  __/  ____) |  | |   _| |_
# |____/ \___| \_/\_/ \__,_|_|  \___| |_____/   |_|  |_____|
class OrderAdjustment < Chargeable
  class RefundableValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, _value)
      message = options[:message] || :balance_exceeded
      record.errors.add(attribute, message, attribute: attribute) if record.refund_exceeds_avaliable_balance?
    end
  end
  include WisperAdapter

  belongs_to :reason, class_name: 'OrderAdjustmentReason'
  belongs_to :user

  belongs_to :shipment
  has_one :initial_charge, through: :shipment
  has_many :charges, through: :shipment

  delegate :customer_facing_name, to: :reason, allow_nil: true, prefix: true
  delegate :name, to: :reason, allow_nil: true, prefix: true

  # TODO: JM: We should validate a credit amount against charge#balance.
  validates :reason, :description, presence: true
  validates :amount, refundable: true, if: :credit?

  after_commit :publish_financial_adjustment_created, on: :create, if: :financial?
  after_commit :publish_order_adjustment_created, on: :create

  ADJUSTMENT_TYPES = %w[coupon credit_card].freeze
  enum adjustment_type: ADJUSTMENT_TYPES

  # TODO: JM: We will eventually need a state_machiine here. I'd suggest statesman
  # as we may want to see the history of financial adjustments. Possible states;
  # credit: :intial -> :approved -> :processed -> :invoiced
  # debit: :intial -> :approved -> :processed -> :invoiced
  #
  # Probably no need for any states on non financial adjustments.

  OUT_OF_STOCK_NAMES = [
    'Item Replacement - No Price Difference',
    'Item Replacement - Lower Value',
    'Item Replacement - Higher Value',
    'Item Replacement - Paid by Minibar',
    'Item Replacement - Item Removed',
    'Out of Stock'
  ].freeze

  #------------------------------------------------------------
  # Scopes
  #------------------------------------------------------------
  # TODO: JM: Need to change this when we implement approvals if we use a state machine.
  scope :processed, -> { where processed: true }
  scope :unprocessed, -> { where processed: false }
  scope :financial, -> { where financial: true }
  scope :credit, -> { where credit: true }
  scope :waiting_charge_settlement, -> { unprocessed.financial.credit }

  #------------------------------------------------------------
  # Class Methods
  #------------------------------------------------------------
  def self.adjustment_total
    where.not(amount: nil).to_a.sum { |a| a.credit ? (a.amount * -1) : a.amount }
  end

  #------------------------------------------------------------
  # Instance Methods
  #------------------------------------------------------------
  def braintree_payment_profile_token
    @braintree_token ||= order.payment_profile.braintree_token
  end

  def total_credit_card_balance
    charges.sum(&:balance)
  end

  def full_refund?
    credit? && amount == total_credit_card_balance
  end

  def merchant_account_id
    @merchant_account_id ||= supplier.get_braintree_merchant_account_id
  end

  def coupon_decreasing_balance
    # Horrible hack to get around not being able to access the coupon
    # at initialization. It's an indication of how tightly coupled the
    # coupon code is to order.
    super || order&.coupon_decreasing_balance
  end

  def order_covered_by_decreasing_coupon?
    coupon_decreasing_balance && order.covered_by_coupon?
  end

  def waiting_for_settlement?
    !processed? && credit? && initial_charge && amount < initial_charge.balance && !initial_charge.settled?
  end

  def process
    # TECH-4381: Added some logs in case the issue happens again
    Rails.logger.warn("processing_order_adjustment_#{id} processed?: #{processed?}, waiting_for_settlement?: #{waiting_for_settlement?}")
    return if processed? || waiting_for_settlement?

    update_attribute(:processed, true) if process_financial_adjustment
  end

  def charge_coupon(total_amount, coupon)
    if coupon.balance > total_amount
      CouponBalanceAdjustment.create!(amount: total_amount, debit: !credit?, order_id: order.id, coupon_id: coupon.id)
      total_amount = 0
    else
      CouponBalanceAdjustment.create!(amount: coupon.balance, debit: !credit?, order_id: order.id, coupon_id: coupon.id)
      total_amount -= coupon.balance
    end
    total_amount
  end

  def refund_coupon(total_amount, coupon)
    coupon_used_amount = order.amount_covered_by_coupon(coupon.id)
    if coupon_used_amount.positive?
      if coupon_used_amount > total_amount
        CouponBalanceAdjustment.create!(amount: total_amount, debit: !credit?, order_id: order.id, coupon_id: coupon.id)
        total_amount = 0
      else
        CouponBalanceAdjustment.create!(amount: coupon_used_amount, debit: !credit?, order_id: order.id, coupon_id: coupon.id)
        total_amount -= coupon_used_amount
      end
    end
    total_amount
  end

  def create_coupon_adjustment!
    coupons = order.all_gift_card_coupons
    total_amount = amount
    coupons.each do |coupon|
      next unless total_amount.positive?

      if credit?
        total_amount = refund_coupon(total_amount, coupon)
      elsif coupon.balance.positive?
        total_amount = charge_coupon(total_amount, coupon)
      end
    end
  end

  def process_financial_adjustment
    return true if amount.zero?

    if credit?
      refund_customer
    else
      charge_customer
    end
  end

  def refund_exceeds_avaliable_balance?
    return false if shipment.canceled?

    if coupon?
      amount > order.amount_covered_with_coupon
    elsif charges.any?
      amount > total_credit_card_balance
    else
      false
    end
  end

  def refund_customer
    if coupon?
      create_coupon_adjustment!
    elsif full_refund?
      charges.each(&:cancel!)
    else
      to_refund = amount

      charges_with_balance.each do |charge|
        next if to_refund.zero?

        refund_message = "[OrderAdjustment] refund for order #{order.number} / #{id} / #{charge.transaction_id}"
        if charge.balance >= to_refund
          Rails.logger.warn("#{refund_message} for #{to_refund}")
          charge.refund!(to_refund)
          to_refund = 0
        else
          Rails.logger.warn("#{refund_message} for #{charge.balance}")
          to_refund -= charge.balance
          charge.cancel!
        end
      end
    end
  end

  def charge_customer
    if coupon?
      create_coupon_adjustment!
    else
      charge ||= create_charge! # This prevents generating multiple charges for the same OA
      charge.authorize!(submit_for_settlement: true) unless charge.transaction_id
    end
  end

  def publish_order_adjustment_created
    broadcast_event(:created, prefix: true)
  end

  def publish_financial_adjustment_created
    broadcast :financial_order_adjustment_created, String(to_global_id)
  end

  def process_without_delay
    ProcessFinancialOrderAdjustmentWorker.perform_async(String(to_global_id))
  end

  def charges_with_balance
    if taxes?
      Charge.includes(:chargeable)
            .joins(:chargeable)
            .where("chargeables.taxes = true AND (chargeables.order_id = #{shipment.order_id} OR chargeables.shipment_id = #{shipment.id})")
            .select(&:balance?)
    else
      charges.select do |charge|
        charge.balance? && !charge.chargeable.taxes
      end
    end
  end
end
