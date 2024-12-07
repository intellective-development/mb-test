# == Schema Information
#
# Table name: membership_plans
#
#  id                                   :integer          not null, primary key
#  state                                :integer
#  storefront_id                        :integer
#  plan_id                              :string
#  name                                 :string
#  billing_day_of_month                 :integer
#  billing_frequency                    :integer          default(12), not null
#  price                                :decimal(8, 2)    default(0.0)
#  engraving_percent_off                :decimal(8, 2)    default(0.0)
#  free_on_demand_fulfillment_threshold :decimal(8, 2)    default(0.0)
#  free_shipping_fulfillment_threshold  :decimal(8, 2)    default(0.0)
#  no_service_fee                       :boolean          default(FALSE)
#  created_at                           :datetime         not null
#  updated_at                           :datetime         not null
#  trial_duration                       :integer
#  trial_duration_unit                  :integer
#  trial_period                         :boolean          default(FALSE), not null
#
# Indexes
#
#  index_membership_plans_on_storefront_id  (storefront_id)
#
class MembershipPlan < ActiveRecord::Base
  include MembershipAble

  enum state: { active: 0, inactive: 1, archived: 2 }

  belongs_to :storefront, inverse_of: :membership_plans
  has_many :memberships, inverse_of: :membership_plan, dependent: nil
  has_many :orders, inverse_of: :membership_plan, dependent: nil

  validates :storefront, presence: true
end
