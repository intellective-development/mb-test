# == Schema Information
#
# Table name: order_survey_suppliers
#
#  id              :integer          not null, primary key
#  supplier_id     :integer          not null
#  order_survey_id :integer          not null
#
# Indexes
#
#  index_order_survey_suppliers_on_order_survey_id  (order_survey_id)
#  index_order_survey_suppliers_on_supplier_id      (supplier_id)
#

class OrderSurveySupplier < ActiveRecord::Base
  belongs_to :order_survey
  belongs_to :supplier

  validates :order_survey_id,  presence: true
  validates :supplier_id,      presence: true
end
