module Shared::Helpers::OrderItemHelpers
  def self.get_order_item_with_sku(shipment, sku)
    shipment.order_items.each do |i|
      return i if i.variant.sku == sku
    end
  end
end
