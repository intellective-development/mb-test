# == Schema Information
#
# Table name: payment_rejection_histories
#
#  id                      :integer          not null, primary key
#  cardholder_name         :string           not null
#  street_address          :string           not null
#  postal_code             :string           not null
#  payment_method_nonce    :string
#  prevented               :boolean          default(FALSE)
#  status                  :string
#  processor_response_type :string
#  processor_response_code :string
#  processor_response_text :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  storefront_id           :integer
#  ip_address              :string
#
# Indexes
#
#  index_payment_rejection_histories_on_storefront_id  (storefront_id)
#  index_payment_rejection_histories_search            (cardholder_name,street_address,postal_code)
#
# Foreign Keys
#
#  fk_rails_...  (storefront_id => storefronts.id)
#
class PaymentRejectionHistory < ApplicationRecord
  belongs_to :storefront, optional: true

  def self.scam?(cardholder_name, address, postal_code)
    setting = PaymentRejectionSetting.first
    return false unless setting

    where(cardholder_name: cardholder_name, street_address: address, postal_code: postal_code)
      .where('created_at > ?', setting.time_range_in_min.minutes.ago).count > setting.attempts
  end
end
