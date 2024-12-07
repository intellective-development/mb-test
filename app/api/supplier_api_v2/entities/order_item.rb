# CK: Note - this differs from API v1 where we represented an array of order items (pre-grouped by variant_id).
#     Now, we are representing a single order item. This will result in legacy orders from before we added
#     OrderItem.quantity from rendering each instance of an item as a separate row.

class SupplierAPIV2::Entities::OrderItem < Grape::Entity
  format_with(:price_formatter) { |value| value&.to_f&.round_at(2) }

  expose :id
  expose :name, &:product_trait_name
  expose :item_size do |order_item|
    order_item.variant.item_volume
  end
  expose :sku do |order_item|
    order_item.variant.sku
  end
  expose :item_options do |order_item|
    SupplierAPIV2::Entities::EngravingOption.represent(order_item.item_options, options) if order_item.item_options.instance_of? EngravingOptions
  end
  expose :volume do |order_item|
    order_item.variant.item_volume
  end
  expose :price, as: :unit_price, format_with: :price_formatter
  expose :quantity
  expose :engraving_location do |_order_item|
    product&.product_trait&.engraving_location
  end
  expose :delivery_expectation do |_order_item|
    product.limited_time_offer_data['delivery_expectation'] if limited_time_offer
  end
  expose :maximum_delivery_expectation do |_order_item|
    product.limited_time_offer_data['maximum_delivery_expectation'] if limited_time_offer
  end

  private

  def product
    object.variant&.product
  end

  def limited_time_offer
    product&.limited_time_offer
  end
end
