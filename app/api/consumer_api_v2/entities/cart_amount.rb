# frozen_string_literal: true

# ConsumerAPIV2::Entities::CartAmount
class ConsumerAPIV2::Entities::CartAmount < Grape::Entity # rubocop:disable Style/ClassAndModuleChildren
  format_with(:float, &:to_f)

  expose :taxes_total, format_with: :float
  expose :taxes do
    expose :sales_tax, format_with: :float
    expose :shipping_tax, as: :shipping, format_with: :float
    expose :on_demand_tax, as: :on_demand, format_with: :float
  end
  expose :fees_total, format_with: :float
  expose :fees do
    expose :bag_fee, as: :bag, format_with: :float
    expose :service_fee, as: :service, format_with: :float
    expose :engraving_fee, as: :engraving, format_with: :float
    expose :retail_delivery_fee, as: :retail_delivery, format_with: :float
    expose :bottle_deposits_fee, as: :bottle_deposit, format_with: :float
    expose :shipping_fee, as: :shipping, format_with: :float
    expose :on_demand_fee, as: :on_demand, format_with: :float
  end
  expose :discounts_total, format_with: :float
  expose :discounts do
    expose :shipping_discount, as: :shipping, format_with: :float
    expose :on_demand_discount, as: :on_demand, format_with: :float
    expose :engraving_discount, as: :engraving, format_with: :float
    expose :service_discount, as: :service, format_with: :float
    expose :sales_discount, as: :sales, format_with: :float
    expose :gift_card_discount, as: :gift_card, format_with: :float
  end
  expose :tip, format_with: :float
  expose :subtotal, format_with: :float
  expose :total, format_with: :float

  def taxes_total
    object.sales_tax + object.shipping_tax + object.on_demand_tax
  end

  def fees_total
    [object.bag_fee,
     object.service_fee,
     object.engraving_fee,
     object.retail_delivery_fee,
     object.bottle_deposits_fee,
     object.shipping_fee,
     object.on_demand_fee].sum
  end

  def discounts_total
    [object.shipping_discount,
     object.on_demand_discount,
     object.engraving_discount,
     object.service_discount,
     object.sales_discount,
     object.gift_card_discount].sum
  end
end
