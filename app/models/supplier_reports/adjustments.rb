# == Schema Information
#
# Table name: supplier_reports_adjustments
#
#  supplier_id     :integer
#  order_number    :string(255)
#  order_date      :datetime
#  adjustment_type :text
#  amount          :money
#  reason          :string(255)
#

class SupplierReports::Adjustments < ActiveRecord::Base
  #----------------------------------------------------------------------
  # Scopes
  #----------------------------------------------------------------------
  scope :between_dates, ->(start_at, end_at) { where('order_date >= :start_at AND order_date <= :end_at', start_at: start_at, end_at: end_at) }
end
