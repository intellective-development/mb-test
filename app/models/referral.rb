# == Schema Information
#
# Table name: referrals
#
#  id                :integer          not null, primary key
#  purchased_at      :datetime
#  referral_user_id  :integer
#  referring_user_id :integer          not null
#  created_at        :datetime
#  updated_at        :datetime
#  applied           :boolean          default(FALSE), not null
#  coupon_id         :integer
#
# Indexes
#
#  index_referrals_on_referral_user_id   (referral_user_id)
#  index_referrals_on_referring_user_id  (referring_user_id)
#

class Referral < ActiveRecord::Base
  belongs_to :referring_user,  class_name: 'User'
  belongs_to :referral_user,   class_name: 'User'
  belongs_to :coupon, optional: true

  validates :referral_user, :referring_user, presence: true

  after_create :issue_reward

  def referral_user_name
    referral_user_id ? referral_user.name : 'N/A'
  end

  def purchased?
    purchased_at?
  end

  def issue_reward
    if referring_user && purchased? && !applied
      coupon = CouponValue.generate_referral_reward(referring_user)
      update!(coupon_id: coupon.id, applied: true)
      UserReferralRewardMailWorker.perform_in(1.minute, id)
    end
  end

  def self.unapplied
    where(applied: false)
  end
end
