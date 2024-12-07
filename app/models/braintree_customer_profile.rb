# == Schema Information
#
# Table name: braintree_customer_profiles
#
#  id                  :integer          not null, primary key
#  user_id             :integer
#  customer_id         :string           not null
#  merchant_account_id :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_braintree_customer_profiles_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class BraintreeCustomerProfile < ApplicationRecord
  validates :customer_id, :merchant_account_id, presence: true
  validates :merchant_account_id, uniqueness: { scope: :user_id }
end
