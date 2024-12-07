# == Schema Information
#
# Table name: invoicing_ledger_items
#
#  id                           :integer          not null, primary key
#  sender_id                    :integer
#  recipient_id                 :integer
#  type                         :string(255)
#  issue_date                   :datetime
#  currency                     :string(3)        not null
#  total_amount                 :decimal(20, 4)
#  tax_amount                   :decimal(20, 4)
#  status                       :string(20)
#  identifier                   :string(50)
#  description                  :string(255)
#  period_start                 :datetime
#  period_end                   :datetime
#  uuid                         :string(40)
#  due_date                     :datetime
#  created_at                   :datetime
#  updated_at                   :datetime
#  minibar_percent              :decimal(, )
#  business_id                  :integer          default(1)
#  sub_total                    :decimal(, )
#  taxed_amount                 :decimal(, )
#  tip_amount                   :decimal(, )
#  shipping_charges             :decimal(, )
#  items_total_amount           :decimal(, )
#  supplier_funded_discounts    :decimal(, )
#  minibar_funded_discounts     :decimal(, )
#  net_amount                   :decimal(, )
#  bottle_deposits              :decimal(, )
#  promo_codes_discount         :decimal(, )
#  shipping_reimbursement_total :decimal(, )
#  gift_card_amount             :decimal(, )
#  paypal_funds                 :decimal(, )
#  marketing_fee                :decimal(, )
#  invoiced_shipments           :integer
#
# Indexes
#
#  index_invoicing_ledger_items_on_id_and_type   (id,type)
#  index_invoicing_ledger_items_on_recipient_id  (recipient_id)
#  index_invoicing_ledger_items_on_uuid          (uuid)
#

class SupplierInvoice < InvoicingLedgerItem
  acts_as_invoice

  def pay_to_data
    StorefrontPaymentInformationService.send(minibar? ? 'minibar' : 'reservebar')
  end
end
