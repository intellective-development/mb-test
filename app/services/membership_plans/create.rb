module MembershipPlans
  class Create < Base
    def initialize(params)
      @params = params
    end

    def call
      @success = MembershipPlan.transaction do
        membership_plan.save!
        membership_plan.update!(plan_id: plan_id)
        plan_api.create!(
          membership_plan
            .slice(
              :billing_day_of_month, :billing_frequency, :trial_period, :trial_duration, :trial_duration_unit
            )
            .symbolize_keys
            .merge(id: plan_id, price: membership_plan.price.to_s, currency_iso_code: 'USD', name: name)
        )
        true
      rescue ActiveRecord::RecordInvalid, Braintree::ValidationsFailed, Braintree::NotFoundError
        raise ActiveRecord::Rollback
      end
      self
    end
  end
end
