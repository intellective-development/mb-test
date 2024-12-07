# == Schema Information
#
# Table name: price_tiers
#
#  id         :integer          not null, primary key
#  coupon_id  :integer
#  minimum    :decimal(, )
#  percent    :integer
#  created_at :datetime
#  updated_at :datetime
#  amount     :decimal(, )
#

class PriceTier < ActiveRecord::Base
  belongs_to :coupon, class_name: 'CouponTiered'

  validates :minimum, uniqueness: { scope: :coupon_id }
end
