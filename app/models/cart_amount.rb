# frozen_string_literal: true

# == Schema Information
#
# Table name: cart_amounts
#
#  id                  :bigint(8)        not null, primary key
#  sales_tax           :decimal(8, 2)    default(0.0)
#  shipping_tax        :decimal(8, 2)    default(0.0)
#  bag_fee             :decimal(8, 2)    default(0.0)
#  service_fee         :decimal(8, 2)    default(0.0)
#  engraving_fee       :decimal(8, 2)    default(0.0)
#  retail_delivery_fee :decimal(8, 2)    default(0.0)
#  bottle_deposits_fee :decimal(8, 2)    default(0.0)
#  shipping_fee        :decimal(8, 2)    default(0.0)
#  gift_card_discount  :decimal(8, 2)    default(0.0)
#  subtotal            :decimal(8, 2)    default(0.0)
#  total               :decimal(8, 2)    default(0.0)
#  tip                 :decimal(8, 2)    default(0.0)
#  cart_id             :bigint(8)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  shipping_discount   :decimal(10, 2)   default(0.0)
#  on_demand_discount  :decimal(10, 2)   default(0.0)
#  engraving_discount  :decimal(10, 2)   default(0.0)
#  service_discount    :decimal(10, 2)   default(0.0)
#  sales_discount      :decimal(10, 2)   default(0.0)
#  on_demand_fee       :decimal(10, 2)   default(0.0)
#  on_demand_tax       :decimal(10, 2)   default(0.0)
#
# Indexes
#
#  index_cart_amounts_on_cart_id  (cart_id)
#
# Foreign Keys
#
#  fk_rails_...  (cart_id => carts.id)
#
class CartAmount < ApplicationRecord
  belongs_to :cart
end
