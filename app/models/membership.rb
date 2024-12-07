# == Schema Information
#
# Table name: memberships
#
#  id                                   :integer          not null, primary key
#  state                                :integer
#  storefront_id                        :integer
#  user_id                              :integer
#  payment_profile_id                   :integer
#  membership_plan_id                   :integer
#  subscription_id                      :string
#  first_name                           :string
#  last_name                            :string
#  last_sign_in_at                      :datetime
#  braintree_token                      :string
#  braintree_plan_id                    :string
#  canceled_at                          :datetime
#  last_payment_at                      :datetime
#  next_payment_at                      :datetime
#  membership_months_active             :bigint(8)        default(0)
#  membership_order_count               :bigint(8)        default(0)
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
#  braintree_merchant_account_id        :string
#  trial_duration                       :integer
#  trial_duration_unit                  :integer
#  trial_period                         :boolean          default(FALSE), not null
#  paid_through_date                    :datetime
#  original_paid_through_date           :datetime
#
# Indexes
#
#  index_memberships_on_membership_plan_id  (membership_plan_id)
#  index_memberships_on_payment_profile_id  (payment_profile_id)
#  index_memberships_on_storefront_id       (storefront_id)
#  index_memberships_on_user_id             (user_id)
#
class Membership < ActiveRecord::Base
  include MembershipAble
  include Iterable::Storefront::Serializers::MembershipSerializer

  enum state: { active: 0, canceled: 1, expired: 2, past_due: 3, pending: 4 }

  belongs_to :user
  belongs_to :storefront, inverse_of: :memberships
  belongs_to :payment_profile, inverse_of: :memberships
  belongs_to :membership_plan, inverse_of: :memberships

  has_many :transactions,
           inverse_of: :membership, class_name: 'MembershipTransaction',
           primary_key: :subscription_id, foreign_key: :subscription_id
  has_many :orders, inverse_of: :membership
  has_many :disputes

  has_one :base_order, ->(instance) { where(membership_plan_id: instance.membership_plan_id) }, class_name: 'Order'

  scope :by_storefront_id, ->(storefront_id) { where(storefront_id: storefront_id) }
  scope :by_first_name, ->(name) { where('first_name ILIKE :name', name: "%#{name}%") }
  scope :by_last_name, ->(name) { where('last_name ILIKE :name', name: "%#{name}%") }
  scope :by_user_email, lambda { |email|
    joins(:user)
      .joins('INNER JOIN registered_accounts ON registered_accounts.id = users.account_id')
      .where('registered_accounts.email ILIKE :email
              OR registered_accounts.contact_email ILIKE :email', email: "%#{email.squish}%")
  }
  scope :by_user_phone, lambda { |phone|
    joins(user: :shipping_addresses)
      .where(
        "NULLIF(regexp_replace(addresses.phone, '\D','','g'), '') ILIKE :phone",
        phone: "%#{phone.gsub(/\D/, '')}%"
      )
  }
  scope :active, -> { where(state: :active).or(where('paid_through_date > ?', Time.zone.now.beginning_of_day)) }

  def customer_name
    "#{first_name} #{last_name}"
  end

  def active?
    state == 'active' || (paid_through_date && paid_through_date > Time.zone.now.beginning_of_day)
  end

  def inactive?
    !active?
  end
end
