class ConsumerAPIV2::Entities::ShipmentAmount < Grape::Entity
  format_with(:float) { |v| Float(v.to_f) }

  expose :sub_total, format_with: :float
  expose :taxed_amount, format_with: :float
  expose :coupon_amount, format_with: :float
  expose :shipping_charges, format_with: :float
  expose :tip_amount, format_with: :float
  expose :deals_total, format_with: :float
  expose :discounts_total, format_with: :float
  expose :taxed_total, format_with: :float
  expose :total_before_discounts, format_with: :float
  expose :bottle_deposits, format_with: :float
  expose :order_items_tax, format_with: :float
  expose :order_items_total, format_with: :float
  expose :shipping_tax, format_with: :float
  expose :total_before_coupon_applied, format_with: :float
  expose :shoprunner_total, format_with: :float
  expose :gift_card_amount, format_with: :float
  expose :additional_tax_amount, format_with: :float
  expose :bag_fee, format_with: :float
  expose :engraving_fee, format_with: :float
  expose :engraving_fee_discounts, format_with: :float
  expose :engraving_fee_after_discounts, format_with: :float
  expose :delivery_fee_discounts_total, format_with: :float
  expose :shipping_fee_discounts_total, format_with: :float
  expose :retail_delivery_fee, format_with: :float
  expose :membership_discount, format_with: :float
  expose :fulfillment_fee, format_with: :float
  expose :membership_shipping_discount, format_with: :float
  expose :membership_delivery_discount, format_with: :float
end
