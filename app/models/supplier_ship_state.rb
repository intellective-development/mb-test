# == Schema Information
#
# Table name: supplier_ship_states
#
#  id               :integer          not null, primary key
#  supplier_id      :integer
#  ship_category_id :integer
#  states           :json
#  ship_level       :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_supplier_ship_states_on_ship_category_id                 (ship_category_id)
#  index_supplier_ship_states_on_supplier_and_category_and_level  (supplier_id,ship_category_id,ship_level) UNIQUE
#  index_supplier_ship_states_on_supplier_id                      (supplier_id)
#
class SupplierShipState < ActiveRecord::Base
  belongs_to :supplier
  belongs_to :ship_category

  enum ship_level: { primary: 'primary', secondary: 'secondary' }
end
