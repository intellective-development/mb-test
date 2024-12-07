module Memberships
  class Create < Base
    def initialize(storefront:, user:, payment_profile:, params: {})
      @storefront = storefront
      @user = user
      @payment_profile = payment_profile
      @params = params
    end

    def call
      @success = Membership.transaction do
        membership.save!
        user.update!(subscription_member: true)
        result = subscription_api.create!(
          payment_method_token: membership.braintree_token,
          plan_id: membership.braintree_plan_id,
          merchant_account_id: membership.braintree_merchant_account_id,
          **discounts
        )
        membership.update!(
          subscription_id: result.id,
          state: result.status.downcase.gsub(/\s/, '_'),
          last_payment_at: result.transactions.first&.created_at,
          next_payment_at: result.next_billing_date.to_datetime,
          paid_through_date: result.paid_through_date.to_datetime,
          original_paid_through_date: result.paid_through_date.to_datetime
        )
      rescue StandardError => e
        Memberships::Refund.new(membership: membership, subscription: result).call if result
        raise e unless RESCUE_ERRORS.any? { |klass| e.is_a?(klass) }

        raise ActiveRecord::Rollback
      end

      Memberships::SendMembershipCreatedEventWorker.perform_async(membership.id) if @success

      self
    end

    def default_params
      super.merge(membership_months_active: 0, membership_order_count: 0)
    end

    class << self
      def call_from_order!(order)
        params = { membership_plan: order.membership_plan, discount: order.membership_coupon_discount }
        new(storefront: order.storefront, user: order.user, payment_profile: order.payment_profile, params: params).call
      end
    end
  end
end
