# == Schema Information
#
# Table name: supplier_reports_orders
#
#  supplier_id        :integer
#  order_number       :string(255)
#  order_date         :datetime
#  subtotal           :money
#  bottle_deposit_fee :money
#  tax                :money
#  tip                :money
#  delivery_fee       :money
#  store_discounts    :money
#  minibar_discounts  :money
#  total              :money
#  customer_name      :text
#  address_1          :string(255)
#  address_2          :string(255)
#  city               :string(255)
#  state_name         :string(255)
#  zip_code           :string(255)
#  shipping_type      :text
#  phone              :string
#  gift_message       :text
#  driver_name        :text
#  state              :text
#  engraving          :boolean
#  storefront_name    :string
#

class SupplierReports::Orders < ActiveRecord::Base
  #----------------------------------------------------------------------
  # Scopes
  #----------------------------------------------------------------------
  scope :between_dates, ->(start_at, end_at) { where('order_date >= :start_at AND order_date <= :end_at', start_at: start_at, end_at: end_at) }
  scope :unconfirmed, -> { where(state: 'unconfirmed') }
  scope :shipped, -> { where(shipping_type: 'shipped') }
  scope :on_demand, -> { where(shipping_type: 'on_demand') }
end
