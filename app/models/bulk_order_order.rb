# == Schema Information
#
# Table name: bulk_order_orders
#
#  id                  :integer          not null, primary key
#  number              :string
#  state               :integer
#  confirmed_at        :datetime
#  scheduled_for       :datetime
#  delivery_notes      :text
#  email               :string
#  bulk_order_id       :integer
#  cart_id             :integer
#  order_id            :integer
#  gift_detail_id      :integer
#  coupon_id           :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  first_name          :string           not null
#  last_name           :string           not null
#  company             :string
#  phone               :string
#  gift_message        :string
#  gift_from           :string
#  quantity            :integer          not null
#  address_id          :integer          not null
#  user_id             :integer          not null
#  product_id          :integer
#  order_errors        :text
#  invoice_total       :decimal(8, 2)    default(0.0)
#  invoice_taxes       :decimal(8, 2)    default(0.0)
#  invoice_bag_fee     :decimal(8, 2)    default(0.0)
#  invoice_subtotal    :decimal(8, 2)    default(0.0)
#  invoice_delivery    :decimal(8, 2)    default(0.0)
#  invoice_tip_amount  :decimal(8, 2)    default(0.0)
#  invoice_service_fee :decimal(8, 2)    default(0.0)
#
# Indexes
#
#  index_bulk_order_orders_on_address_id      (address_id)
#  index_bulk_order_orders_on_bulk_order_id   (bulk_order_id)
#  index_bulk_order_orders_on_cart_id         (cart_id)
#  index_bulk_order_orders_on_coupon_id       (coupon_id)
#  index_bulk_order_orders_on_gift_detail_id  (gift_detail_id)
#  index_bulk_order_orders_on_order_id        (order_id)
#  index_bulk_order_orders_on_product_id      (product_id)
#  index_bulk_order_orders_on_user_id         (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#  fk_rails_...  (bulk_order_id => bulk_orders.id)
#  fk_rails_...  (cart_id => carts.id)
#  fk_rails_...  (coupon_id => coupons.id)
#  fk_rails_...  (gift_detail_id => gift_details.id)
#  fk_rails_...  (order_id => orders.id)
#  fk_rails_...  (product_id => products.id)
#  fk_rails_...  (user_id => users.id)
#
class BulkOrderOrder < ActiveRecord::Base
  belongs_to :gift_detail
  belongs_to :cart
  belongs_to :coupon
  belongs_to :bulk_order
  belongs_to :order
  belongs_to :user

  belongs_to :address
end
