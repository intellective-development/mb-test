# == Schema Information
#
# Table name: customer_refunds
#
#  id             :integer          not null, primary key
#  charge_id      :integer
#  amount         :float
#  transaction_id :string(64)
#  created_at     :datetime
#  updated_at     :datetime
#  metadata       :json
#
# Indexes
#
#  index_customer_refunds_on_charge_id  (charge_id)
#

class CustomerRefund < ActiveRecord::Base
  belongs_to :charge
  has_one :chargeable, through: :charge

  validates :charge, :amount, :transaction_id, presence: true
  validates :amount, numericality: true
end
