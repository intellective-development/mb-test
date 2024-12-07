# == Schema Information
#
# Table name: shipment_amounts
#
#  id                            :integer          not null, primary key
#  shipment_id                   :integer
#  line_item_id                  :integer
#  sub_total                     :decimal(20, 4)   default(0.0)
#  taxed_amount                  :decimal(20, 4)   default(0.0), not null
#  coupon_amount                 :decimal(20, 4)   default(0.0), not null
#  shipping_charges              :decimal(20, 4)   default(0.0), not null
#  tip_amount                    :decimal(20, 4)   default(0.0), not null
#  created_at                    :datetime
#  updated_at                    :datetime
#  deals_total                   :decimal(8, 2)    default(0.0)
#  discounts_total               :decimal(8, 2)    default(0.0)
#  taxed_total                   :decimal(8, 2)    default(0.0)
#  total_before_discounts        :decimal(8, 2)    default(0.0)
#  bottle_deposits               :decimal(8, 2)    default(0.0), not null
#  order_items_tax               :decimal(8, 2)    default(0.0)
#  order_items_total             :decimal(8, 2)    default(0.0)
#  shipping_tax                  :decimal(8, 2)    default(0.0), not null
#  total_before_coupon_applied   :decimal(8, 2)    default(0.0)
#  shoprunner_total              :decimal(8, 2)    default(0.0)
#  gift_card_amount              :decimal(8, 2)    default(0.0)
#  additional_tax_amount         :decimal(8, 2)    default(0.0)
#  bag_fee                       :decimal(8, 2)    default(0.0), not null
#  engraving_fee                 :decimal(8, 2)    default(0.0)
#  engraving_fee_discounts       :decimal(8, 2)    default(0.0)
#  engraving_fee_after_discounts :decimal(8, 2)    default(0.0)
#  delivery_fee_discounts_total  :decimal(8, 2)    default(0.0), not null
#  shipping_fee_discounts_total  :decimal(8, 2)    default(0.0), not null
#  retail_delivery_fee           :decimal(9, 2)    default(0.0)
#  membership_discount           :decimal(8, 2)
#  fulfillment_fee               :decimal(8, 2)
#  membership_shipping_discount  :decimal(8, 2)
#  membership_delivery_discount  :decimal(8, 2)
#  line_item_cancellation_id     :integer
#
# Indexes
#
#  index_shipment_amounts_on_line_item_cancellation_id  (line_item_cancellation_id)
#  index_shipment_amounts_on_line_item_id               (line_item_id)
#  index_shipment_amounts_on_shipment_id                (shipment_id)
#

# TODO: should shipments have the shipment_amount id instead of the link here?
# similar line of thinking as order_amounts

class ShipmentAmount < ActiveRecord::Base
  belongs_to :shipment, inverse_of: :shipment_amount, touch: true
  belongs_to :line_item, class_name: 'InvoicingLineItem'
  belongs_to :line_item_cancellation, class_name: 'InvoicingLineItem'

  before_save :check_mutability

  def check_mutability
    line_item_id_was.nil? || line_item_id.nil?
  end

  def not_invoiced?
    line_item_id.nil?
  end

  def promo_codes_discount
    coupon_amount - gift_card_amount
  end

  def shipping_reimbursement_total
    (shipping_fee_discounts_total.to_f + delivery_fee_discounts_total.to_f).round 2
  end

  def minibar_funded_discounts
    (shipping_reimbursement_total + discounts_total.to_f - supplier_funded_discounts.to_f).round(2)
  end

  def supplier_funded_discounts
    # Currently suppliers only pay for specific types of deals (usually volume discounts). Coupons,
    # ShopRunner and other deals are all funded by Minibar for supplier invoicing/reporting purposes.
    shipment.applied_deals.where(sponsor_type: 'Supplier').sum(:value).to_f.round(2)
  end

  def total_amount
    total = sub_total.to_f + taxed_amount.to_f + tip_amount.to_f + shipping_charges.to_f - discounts_total.to_f
    total = 0.0 if total.negative?
    total.round(2)
  end

  def receipt_total
    total = sub_total.to_f + tip_amount.to_f + bottle_deposits.to_f + shipping_charges.to_f + bag_fee.to_f
    total = 0.0 if total.negative?
    total.round(2)
  end

  def total_amount_with_engraving
    total_amount + engraving_fee_after_discounts
  end

  def sub_total_with_engraving
    sub_total + engraving_fee
  end

  def tax_discounting_bottle_fee
    taxed_amount - bottle_deposits
  end

  def sales_tax
    taxed_amount - bottle_deposits - bag_fee
  end

  def fees_due_retailer
    bottle_deposits + bag_fee
  end

  def taxes_due_minibar
    shipping_tax + order_items_tax + retail_delivery_fee
  end
end
