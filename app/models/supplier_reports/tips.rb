# == Schema Information
#
# Table name: supplier_reports_tips
#
#  supplier_id :integer
#  order_date  :datetime
#  order_state :string(255)
#  driver_name :text
#  total_tips  :money
#

class SupplierReports::Tips < ActiveRecord::Base
  #----------------------------------------------------------------------
  # Scopes
  #----------------------------------------------------------------------
  scope :between_dates, ->(start_at, end_at) { where('order_date >= :start_at AND order_date <= :end_at', start_at: start_at, end_at: end_at) }
end
