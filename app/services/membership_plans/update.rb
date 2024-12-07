module MembershipPlans
  class Update < Base
    BRAINTREE_KEYS = %w[price plan_id name billing_day_of_month trial_period trial_duration trial_duration_unit].freeze
    attr_accessor :membership_plan

    def initialize(membership_plan, params)
      @membership_plan = membership_plan
      @params = params
    end

    def call
      @success = MembershipPlan.transaction do
        membership_plan.update!(
          default_params.merge(params).except(:billing_frequency)
        )
        if (membership_plan.previous_changes.keys & BRAINTREE_KEYS).count.positive?
          plan_api.update!(
            plan_id,
            membership_plan
              .slice(:billing_day_of_month, :trial_period, :trial_duration, :trial_duration_unit)
              .symbolize_keys
              .merge(id: plan_id, price: membership_plan.price.to_s, currency_iso_code: 'USD', name: name)
          )
        end
        true
      rescue ActiveRecord::RecordInvalid, Braintree::ValidationsFailed, Braintree::NotFoundError
        raise ActiveRecord::Rollback
      end
      self
    end

    def default_params
      super.merge(plan_id: plan_id)
    end
  end
end
