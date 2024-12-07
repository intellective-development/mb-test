# == Schema Information
#
# Table name: fulfillment_services
#
#  id                  :integer          not null, primary key
#  name                :string
#  pim_name            :string
#  status              :string           default("active"), not null
#  supplier_modifiable :boolean          default(FALSE)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_fulfillment_services_on_name  (name) UNIQUE
#
class FulfillmentService < ActiveRecord::Base
  has_paper_trail

  has_and_belongs_to_many :suppliers

  validates :name, uniqueness: true

  enum status: { active: 'active', inactive: 'inactive' }

  scope :by_status, ->(status) { where(status: status) }
  scope :by_name,   ->(name)   { where('name ILIKE :name OR pim_name ILIKE :name', name: "%#{name}%") }
end
