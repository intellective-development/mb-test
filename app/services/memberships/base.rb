module Memberships
  class Base
    attr_reader :params, :storefront, :user, :payment_profile

    RESCUE_ERRORS = [
      ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound,
      Braintree::ValidationsFailed, Braintree::NotFoundError
    ].freeze

    def membership
      @membership ||= Membership.new(default_params.merge(params.except(:membership_plan, :discount)))
    end

    def success?
      @success
    end

    protected

    def default_params
      {
        state: :active,
        storefront_id: storefront.id,
        user_id: user.id,
        payment_profile_id: payment_profile.id,
        membership_plan_id: membership_plan.id,
        first_name: user.first_name,
        last_name: user.last_name,
        braintree_token: payment_profile.braintree_token,
        braintree_plan_id: membership_plan.plan_id,
        braintree_merchant_account_id: braintree_merchant_account_id,
        **membership_plan.slice(
          :name,
          :billing_day_of_month,
          :billing_frequency,
          :price,
          :engraving_percent_off,
          :free_on_demand_fulfillment_threshold,
          :free_shipping_fulfillment_threshold,
          :no_service_fee,
          :trial_duration,
          :trial_duration_unit,
          :trial_period
        ).symbolize_keys
      }
    end

    def membership_plan
      @membership_plan ||=
        if params[:membership_plan].present?
          params[:membership_plan]
        elsif params[:membership_plan_id].present?
          MembershipPlan.find(params[:membership_plan_id])
        else
          storefront.membership_plan
        end
    end

    def subscription
      @subscription ||= subscription_api.find(membership.subscription_id)
    end

    def discount
      [membership_plan.price.to_f, params[:discount].to_f].min
    end

    def discounts
      return {} if discount <= 0

      {
        discounts: {
          add: [
            {
              amount: discount,
              inherited_from_id: 'coupon',
              number_of_billing_cycles: 1,
              quantity: 1
            }
          ]
        }
      }
    end

    def braintree_merchant_account_id
      storefront.business&.fee_supplier&.braintree_merchant_account_id
    end

    def subscription_api
      Braintree::Configuration.gateway.subscription
    end

    def transaction_api
      Braintree::Configuration.gateway.transaction
    end
  end
end
