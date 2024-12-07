# == Schema Information
#
# Table name: invoicing_line_items
#
#  id                           :integer          not null, primary key
#  ledger_item_id               :integer
#  type                         :string(255)
#  net_amount                   :decimal(20, 4)
#  tax_amount                   :decimal(20, 4)
#  description                  :string(255)
#  uuid                         :string(40)
#  tax_point                    :datetime
#  quantity                     :decimal(20, 4)
#  creator_id                   :integer
#  created_at                   :datetime
#  updated_at                   :datetime
#  reason                       :text
#  sub_total                    :decimal(, )
#  taxed_amount                 :decimal(, )
#  tip_amount                   :decimal(, )
#  shipping_charges             :decimal(, )
#  total_amount                 :decimal(, )
#  supplier_funded_discounts    :decimal(, )
#  minibar_funded_discounts     :decimal(, )
#  bottle_deposits              :decimal(, )
#  promo_codes_discount         :decimal(, )
#  shipping_reimbursement_total :decimal(, )
#  gift_card_amount             :decimal(, )
#  paypal_funds                 :decimal(, )
#  marketing_fee                :decimal(, )
#  order_number                 :string
#
# Indexes
#
#  index_invoicing_line_items_on_description     (description)
#  index_invoicing_line_items_on_ledger_item_id  (ledger_item_id)
#

class BoozeCarriageOrder < InvoicingLineItem
  acts_as_line_item
end
