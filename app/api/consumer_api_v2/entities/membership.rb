class ConsumerAPIV2::Entities::Membership < Grape::Entity
  format_with(:iso_timestamp) { |dt| dt&.iso8601 }

  expose :name
  expose :state
  expose :storefront_id
  expose :created_at, format_with: :iso_timestamp
  expose :last_payment_at, format_with: :iso_timestamp
  expose :next_payment_at, format_with: :iso_timestamp
  expose :no_service_fee
  expose :engraving_percent_off
  expose :free_on_demand_fulfillment_threshold
  expose :free_shipping_fulfillment_threshold
  expose :billing_day_of_month
  expose :billing_frequency
  expose :trial_duration
  expose :trial_duration_unit
  expose :trial_period
  expose :price do |membership|
    membership.price.to_f.round(2)
  end
  expose :benefits, with: ConsumerAPIV2::Entities::MembershipBenefits do |membership|
    membership
  end
end
