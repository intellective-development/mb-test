module Memberships
  class Cancel < Base
    def initialize(membership:, subscription: nil)
      @membership = membership
      @subscription = subscription
    end

    def call
      @success = Membership.transaction do
        membership.update(state: 'canceled', canceled_at: Time.zone.now)
        subscription_api.cancel!(membership.subscription_id) if subscription.status != Braintree::Subscription::Status::Canceled
        true
      rescue ActiveRecord::RecordInvalid, Braintree::ValidationsFailed, Braintree::NotFoundError
        raise ActiveRecord::Rollback
      end

      Memberships::SendMembershipCancelledEventWorker.perform_async(membership.id) if @success

      self
    end
  end
end
