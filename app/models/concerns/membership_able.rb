module MembershipAble
  extend ActiveSupport::Concern

  included do
    enum trial_duration_unit: { day: 0, month: 1 }
    validates :trial_duration, numericality: { only_integer: true }, allow_nil: true
  end

  def apply_engraving_percent_off?
    engraving_percent_off.to_f.nonzero?
  end

  def free_shipping?(total)
    total >= free_shipping_fulfillment_threshold
  end

  def free_on_demand?(total)
    total >= free_on_demand_fulfillment_threshold
  end
end
