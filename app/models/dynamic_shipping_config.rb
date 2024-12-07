# == Schema Information
#
# Table name: dynamic_shipping_configs
#
#  id                             :integer          not null, primary key
#  fuel_surcharge                 :float            default(0.0), not null
#  adult_signature_surcharge      :float            default(0.0), not null
#  residential_delivery_surcharge :float            default(0.0), not null
#  holiday_surcharge              :float            default(0.0), not null
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  heavy_fee                      :float            default(0.0), not null
#
class DynamicShippingConfig < ApplicationRecord
  HEAVY_WEIGHT_THRESHOLD = 100

  has_paper_trail

  validates :fuel_surcharge, :adult_signature_surcharge, :residential_delivery_surcharge, :holiday_surcharge, presence: true

  def apply_surcharge(base_fee)
    final_fee = base_fee + adult_signature_surcharge + residential_delivery_surcharge + holiday_surcharge
    final_fee *= (1 + fuel_surcharge / 100)

    final_fee.to_f.round_at(2)
  end
end
