# == Schema Information
#
# Table name: cart_traits
#
#  id                 :integer          not null, primary key
#  cart_id            :integer
#  coupon_code        :string
#  gtm_visitor_id     :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  gift_order         :boolean          default(FALSE), not null
#  age_verified       :boolean          default(FALSE), not null
#  decision_log_uuids :jsonb
#  membership_plan_id :bigint(8)
#
# Indexes
#
#  index_cart_traits_on_cart_id             (cart_id)
#  index_cart_traits_on_membership_plan_id  (membership_plan_id)
#
# Foreign Keys
#
#  fk_rails_...  (membership_plan_id => membership_plans.id)
#

class CartTrait < ActiveRecord::Base
  belongs_to :cart, optional: true
  belongs_to :membership_plan, optional: true
end
