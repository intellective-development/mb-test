class ConsumerAPIV2::Entities::MembershipPlan < Grape::Entity
  expose :id
  expose :plan_id
  expose :name
  expose :no_service_fee
  expose :engraving_percent_off
  expose :free_on_demand_fulfillment_threshold
  expose :free_shipping_fulfillment_threshold
  expose :billing_day_of_month
  expose :billing_frequency
  expose :trial_duration
  expose :trial_duration_unit
  expose :trial_period
  expose :price do |membership_plan|
    membership_plan.price.to_f.round(2)
  end
  expose :benefits, with: ConsumerAPIV2::Entities::MembershipBenefits do |membership_plan|
    membership_plan
  end
end
