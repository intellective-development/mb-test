# == Schema Information
#
# Table name: disputes
#
#  id             :integer          not null, primary key
#  kind           :integer
#  reason         :integer
#  status         :integer
#  order_id       :integer
#  transaction_id :string
#  external_id    :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  membership_id  :bigint(8)
#
# Indexes
#
#  index_disputes_on_membership_id  (membership_id)
#  index_disputes_on_order_id       (order_id)
#

class Dispute < ActiveRecord::Base
  belongs_to :order, optional: true
  belongs_to :membership, optional: true

  enum kind: {
    retrieval: 0,
    chargeback: 1,
    pre_arbitration: 2
  }

  # https://developer.paypal.com/braintree/docs/reference/response/dispute
  enum reason: {
    cancelled_recurring_transaction: 0,
    credit_not_processed: 1,
    duplicate: 2,
    fraud: 3,
    general: 4,
    invalid_account: 5,
    not_recognized: 6,
    product_not_received: 7,
    product_unsatisfactory: 8,
    transaction_amount_differs: 9
  }

  enum status: {
    open: 0,
    lost: 1,
    won: 2
  }

  after_commit :publish_dispute_updated
  after_create :expire_order_gift_cards!
  after_create :cancel_membership

  def publish_dispute_updated
    Fraud::ChargebackEvent.new(self).call_async if order
  end

  # TECH-4213 expire order gift cards when chargeback initiates
  def expire_order_gift_cards!
    Coupon::GiftCardExpireWorker.perform_async(order.order_item_ids) if order.present?
  end

  def cancel_membership
    return if membership.nil?

    call_cancel_membership
    notify_on_asana
    add_comment_to_user
  end

  def notify_on_asana
    InternalAsanaNotificationWorker.perform_async(
      tags: [AsanaService::BILLING_ISSUE_TAG_ID],
      name: "Membership fee on dispute - #{membership.customer_name}",
      notes: membership_cancellation_note
    )
  end

  def add_comment_to_user
    membership.user.comments.create(
      note: membership_cancellation_note,
      commentable_type: 'User'
    )
  end

  def membership_cancellation_note
    'Their membership has been cancelled due to a chargeback on the membership fee.'
  end

  def call_cancel_membership
    Memberships::Cancel.new(membership: membership).call
  end
end
