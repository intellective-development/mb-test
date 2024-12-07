# == Schema Information
#
# Table name: supplier_logos
#
#  id          :integer          not null, primary key
#  logo_id     :integer
#  supplier_id :integer
#
# Indexes
#
#  index_supplier_logos_on_logo_id      (logo_id)
#  index_supplier_logos_on_supplier_id  (supplier_id)
#

class SupplierLogo < ActiveRecord::Base
  include Wisper::Publisher

  has_paper_trail

  belongs_to :logo
  belongs_to :supplier

  # after_create :publish_supplier_holiday_created

  # def publish_supplier_holiday_created
  #   broadcast(:supplier_holiday_created, self)
  # end
end
