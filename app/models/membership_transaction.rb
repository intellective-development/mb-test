# == Schema Information
#
# Table name: membership_transactions
#
#  id               :integer          not null, primary key
#  subscription_id  :string
#  transaction_id   :string
#  transaction_type :integer
#  amount           :decimal(8, 2)    default(0.0)
#  status           :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_membership_transactions_on_subscription_id  (subscription_id)
#  index_membership_transactions_on_transaction_id   (transaction_id)
#
class MembershipTransaction < ActiveRecord::Base
  enum transaction_type: { sale: 0, credit: 1 }

  belongs_to :membership, inverse_of: :transactions, primary_key: :subscription_id, foreign_key: :subscription_id
end
