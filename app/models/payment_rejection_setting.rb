# == Schema Information
#
# Table name: payment_rejection_settings
#
#  id                :integer          not null, primary key
#  attempts          :integer          not null
#  time_range_in_min :integer          not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class PaymentRejectionSetting < ApplicationRecord
end
