# == Schema Information
#
# Table name: product_cart_items
#
#  id         :integer          not null, primary key
#  cart_id    :integer
#  product_id :integer
#  quantity   :integer          default(1)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_product_cart_items_on_cart_id     (cart_id)
#  index_product_cart_items_on_product_id  (product_id)
#
# Foreign Keys
#
#  fk_rails_...  (cart_id => carts.id)
#  fk_rails_...  (product_id => products.id)
#

class ProductCartItem < ActiveRecord::Base
  belongs_to :cart, touch: true, class_name: 'ProductCart'
  belongs_to :product
end
