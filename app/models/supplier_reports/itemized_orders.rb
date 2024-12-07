# == Schema Information
#
# Table name: supplier_reports_itemized_orders
#
#  supplier_id   :integer
#  order_number  :string(255)
#  customer_name :text
#  address_1     :string(255)
#  address_2     :string(255)
#  city          :string(255)
#  state_name    :string(255)
#  zip_code      :string(255)
#  phone         :string
#  gift_message  :text
#  order_date    :datetime
#  product_name  :string(255)
#  volume        :text
#  pack_size     :text
#  unit_price    :decimal(8, 2)
#  quantity      :integer
#  item_total    :decimal(8, 2)
#

class SupplierReports::ItemizedOrders < ActiveRecord::Base
  #----------------------------------------------------------------------
  # Scopes
  #----------------------------------------------------------------------
  scope :between_dates, ->(start_at, end_at) { where('order_date >= :start_at AND order_date <= :end_at', start_at: start_at, end_at: end_at) }
end
