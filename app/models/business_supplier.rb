# == Schema Information
#
# Table name: business_suppliers
#
#  id             :integer          not null, primary key
#  business_id    :integer
#  supplier_id    :integer
#  percent_markup :decimal(9, 2)
#  amount_markup  :decimal(9, 2)
#  score          :integer          default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  status         :string           default("active"), not null
#
# Indexes
#
#  index_business_suppliers_on_business_id                  (business_id)
#  index_business_suppliers_on_supplier_id                  (supplier_id)
#  index_business_suppliers_on_supplier_id_and_business_id  (supplier_id,business_id) UNIQUE
#
class BusinessSupplier < ActiveRecord::Base
  belongs_to :business
  belongs_to :supplier

  enum status: { active: 'active', inactive: 'inactive' }

  validates :supplier_id, uniqueness: { scope: :business_id }

  has_paper_trail ignore: %i[created_at updated_at]
end
