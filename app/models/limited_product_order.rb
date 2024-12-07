# == Schema Information
#
# Table name: limited_product_orders
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  order_id   :integer          not null
#  product_id :integer          not null
#  email      :string           not null
#  quantity   :integer          not null
#
# Indexes
#
#  index_limited_product_orders_on_email       (email)
#  index_limited_product_orders_on_order_id    (order_id)
#  index_limited_product_orders_on_product_id  (product_id)
#
class LimitedProductOrder < ActiveRecord::Base
  belongs_to :order
  belongs_to :product

  class << self
    def sum_of_products_in_cart(cart, product, identifier)
      CartItem.joins(:variant)
              .where(cart: cart)
              .where(variants: { product: product })
              .where.not(identifier: identifier)
              .sum(:quantity)
    end

    def sum_of_products_in_order(order, product, identifier)
      OrderItem.joins(:variant).joins(:shipment)
               .where(shipments: { order_id: order.id })
               .where(variants: { product: product })
               .where.not(identifier: identifier)
               .sum(:quantity)
    end

    def limit_reached_in_cart?(cart, product, identifier, quantity = nil)
      max_quantity_per_order = product&.max_quantity_per_order
      return false unless max_quantity_per_order

      (sum_of_products_in_cart(cart, product, identifier) + quantity.to_i) > max_quantity_per_order.to_i
    end

    def limit_reached_in_order?(order, product, identifier, quantity = nil)
      max_quantity_per_order = product.max_quantity_per_order
      return false unless max_quantity_per_order

      (sum_of_products_in_order(order, product, identifier) + quantity.to_i) > max_quantity_per_order.to_i
    end

    def update_purchased_items(order, order_items)
      # remove all data for this order so we dont worry about keeping track of what
      # is and what is not.
      where(order: order).destroy_all

      order_items.each do |order_item|
        product = order_item[:variant].product
        next if product.max_quantity_per_order.nil?

        create!(order: order, product: product, email: order.user.email, quantity: order_item[:quantity])
      end
    end
  end
end
