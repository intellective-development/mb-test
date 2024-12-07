module Memberships
  class Refund < Base
    attr_reader :refund_tax

    def initialize(membership:, user: nil, subscription: nil, refund_tax: false)
      @membership = membership
      @subscription = subscription
      @user = user
      @refund_tax = refund_tax
    end

    def call
      @success = Membership.transaction do
        membership.update!(state: 'canceled', canceled_at: Time.zone.now, paid_through_date: nil)
        refund_membership_tax! if refund_tax
        refund_transaction!(last_transaction) if last_transaction.present?
        subscription_api.cancel!(membership.subscription_id) if subscription.status != Braintree::Subscription::Status::Canceled
        true
      rescue ActiveRecord::RecordInvalid, Braintree::ValidationsFailed, Braintree::NotFoundError
        raise ActiveRecord::Rollback
      end

      Memberships::SendMembershipRefundedEventWorker.perform_async(membership.id) if @success

      self
    end

    private

    def refund_membership_tax!
      @refund_membership_tax ||= ::Memberships::RefundTax.new(membership: @membership, user: user).call
    end

    def refund_transaction!(transaction)
      return transaction_api.void(transaction.id) if PaymentGateway::VOIDABLE_STATUS.include?(transaction.status)
      return transaction_api.refund(transaction.id, transaction.amount) if PaymentGateway::SETTLED_STATUS.include?(transaction.status) && !transaction.refunded?
    end

    def last_transaction
      @last_transaction ||= subscription.transactions.select do |transaction|
        transaction.type == Braintree::Transaction::Type::Sale &&
          PaymentGateway::SETTLED_STATUS.include?(transaction.status) ||
          PaymentGateway::VOIDABLE_STATUS.include?(transaction.status)
      end.max_by(&:created_at)
    end
  end
end
