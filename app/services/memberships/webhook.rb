module Memberships
  class Webhook
    attr_accessor :notification

    SETTLED_STATUSES = [
      Braintree::Transaction::Status::Authorized,
      Braintree::Transaction::Status::Settled,
      Braintree::Transaction::Status::SettlementConfirmed,
      Braintree::Transaction::Status::SettlementPending,
      Braintree::Transaction::Status::Settling,
      Braintree::Transaction::Status::SubmittedForSettlement
    ].freeze

    def initialize(notification)
      @notification = notification
    end

    def call
      return unless notification.subscription
      return retry_later unless membership

      case notification.kind
      when Braintree::WebhookNotification::Kind::SubscriptionChargedSuccessfully
        update_membership_on_success

        Memberships::SendMembershipPaymentCompletedEventWorker.perform_async(membership.id)
        Memberships::SendMembershipRenewalEventWorker.perform_async(membership.id) if membership_renewed?
      when Braintree::WebhookNotification::Kind::SubscriptionWentActive
        update_membership_on_success
      when Braintree::WebhookNotification::Kind::SubscriptionChargedUnsuccessfully
        update_membership_on_fail

        Memberships::SendMembershipPaymentFailedEventWorker.perform_async(membership.id)
      when Braintree::WebhookNotification::Kind::SubscriptionCanceled,
        Braintree::WebhookNotification::Kind::SubscriptionExpired,
        Braintree::WebhookNotification::Kind::SubscriptionTrialEnded,
        Braintree::WebhookNotification::Kind::SubscriptionWentPastDue
        update_membership_on_fail
      end

      update_transactions(notification.subscription.transactions) if notification.subscription&.transactions && notification.subscription&.id
      self
    end

    protected

    def retry_later
      retry_later_params = { kind: notification.kind, subscription_id: notification.subscription.id }

      Memberships::WebhookWorker.perform_in(5.minutes, retry_later_params)
    end

    def membership
      @membership ||= Membership.where(subscription_id: notification.subscription.id).first
    end

    def state
      membership.canceled? ? membership.state : notification.subscription.status.downcase.gsub(/\s/, '_')
    end

    def paid_through_date
      membership.canceled? ? nil : notification.subscription.paid_through_date.to_datetime || notification.subscription.next_billing_date.to_datetime
    end

    def membership_months_active
      ((notification.subscription.next_billing_date - notification.subscription.first_billing_date) * 1.day / 1.month).round
    end

    def last_payment_at
      notification.subscription.transactions.select do |transaction|
        transaction.type == Braintree::Transaction::Type::Sale &&
          SETTLED_STATUSES.include?(transaction.status)
      end.last&.created_at
    end

    def membership_renewed?
      notification.subscription.transactions.count { |t| t.type == Braintree::Transaction::Type::Sale && SETTLED_STATUSES.include?(t.status) } > 1
    end

    def update_transactions(transactions)
      membership_transactions =
        ::MembershipTransaction.where(transaction_id: transactions.map(&:id)).index_by(&:transaction_id)
      transactions.each do |transaction|
        params = {
          subscription_id: notification.subscription.id,
          transaction_id: transaction.id,
          transaction_type: transaction.type,
          status: transaction.status,
          amount: transaction.amount
        }

        next if membership_transactions[transaction.id]&.update(status: transaction.status)

        ::MembershipTransaction.create(params)
      end
    end

    def update_membership_on_success
      membership.update!(
        state: state,
        last_payment_at: last_payment_at,
        next_payment_at: notification.subscription.next_billing_date.to_datetime,
        paid_through_date: paid_through_date,
        original_paid_through_date: paid_through_date,
        membership_months_active: membership_months_active
      )
    end

    def update_membership_on_fail
      membership.update!(
        state: state,
        last_payment_at: last_payment_at,
        next_payment_at: notification.subscription.next_billing_date&.to_datetime,
        membership_months_active: membership_months_active
      )
    end
  end
end
