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

class InvoicingLineItem < ActiveRecord::Base
  acts_as_line_item
  belongs_to :ledger_item, class_name: 'InvoicingLedgerItem'
  has_one :order_adjustment, foreign_key: 'line_item_id'
  has_one :shipment_amount, foreign_key: 'line_item_id'
  has_one :shipment_amount_cancellation, class_name: 'ShipmentAmount', foreign_key: 'line_item_cancellation_id'

  CHARGES_TYPES = %w[AdditionalCharge FlatFee GatewayFee].freeze
  ADJUSTMENT_TYPES = %w[AdditionalCharge Refund].freeze

  validates :type, presence: true
  validates :description, uniqueness: { scope: %i[ledger_item_id type] }

  def refresh
    if shipment_amount
      shipment = shipment_amount.shipment
      self.net_amount = (shipment.invoicing_sub_total * ledger_item.minibar_percent) - shipment_amount.minibar_funded_discounts
      save!
    end
  end

  def detach
    # detach associated models
    shipment_amount&.update_attribute(:line_item_id, nil) unless shipment_amount_cancellation&.line_item_cancellation_id
    shipment_amount_cancellation&.update_attribute(:line_item_cancellation_id, nil)
    order_adjustment&.update_attribute(:line_item_id, nil)
    reload # ensures the models are no longer associated
    # update the description
    desc = description.nil? || description.include?('#VOID#') ? description : "#{description}#VOID#"
    update_attribute(:description, desc)
  end
end
