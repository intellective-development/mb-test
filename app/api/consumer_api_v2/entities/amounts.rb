class ConsumerAPIV2::Entities::Amounts < Grape::Entity
  format_with(:float) { |v| Float(v.to_f) }

  expose :shipping_charges,    as: :shipping,  format_with: :float
  expose :sales_tax,           as: :tax,       format_with: :float
  expose :total_taxed_amount,  as: :tax_total, format_with: :float
  expose :tip_amount,          as: :tip,       format_with: :float, if: ->(instance, _options) { instance.shipping_methods.where(allows_tipping: true).exists? }
  expose :tip_eligible_amount, as: :tip_eligible_amount, format_with: :float, if: ->(instance, _options) { instance.shipping_methods.where(allows_tipping: true).exists? }
  expose :bottle_deposits,     as: :bottle_deposits, format_with: :float
  expose :bag_fee,             as: :bag_fee, format_with: :float
  expose :retail_delivery_fee, as: :retail_delivery_fee, format_with: :float
  expose :taxed_total,         as: :total, format_with: :float
  expose :sub_total_with_engraving, as: :subtotal, format_with: :float
  # TODO: Once Deals have rolled out, deprecate coupon.
  expose :discounts_total, as: :coupon, format_with: :float
  expose :shipping_after_discounts, format_with: :float
  expose :delivery_after_discounts, format_with: :float
  expose :service_fee,                     format_with: :float
  expose :engraving_fee,                   format_with: :float
  expose :potential_membership_savings
  expose :membership_discount, format_with: :float
  expose :membership_price, format_with: :float
  expose :membership_service_fee_discount, format_with: :float
  expose :membership_engraving_fee_discount, format_with: :float
  expose :membership_shipping_discount, format_with: :float
  expose :membership_on_demand_discount, format_with: :float
  expose :fulfillment_fee, format_with: :float
  expose :delivery_charges
  expose :discounts do
    expose :deals_total,    as: :deals,    format_with: :float
    expose :coupon_amount,  as: :coupons,  format_with: :float
  end
  expose :without_digital_total_before_coupon_applied, as: :regular_products_revenue, format_with: :float
  expose :video_gift_fee, format_with: :float, &:video_gift_fee
  expose :current_charge_total,  format_with: :float
  expose :deferred_charge_total, format_with: :float

  def delivery_charges
    object.amounts&.delivery_charges
  end

  def coupon_amount
    current_coupon_amount = object.amounts.coupon_amount
    current_coupon_amount -= object.amounts.delivery_charges[:shipping] if object.free_shipping_coupon?
    current_coupon_amount -= object.amounts.delivery_charges[:on_demand] if object.free_delivery_coupon?

    current_coupon_amount.negative? ? 0.0 : current_coupon_amount.to_f.round_at(2)
  end
end
