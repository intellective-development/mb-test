# == Schema Information
#
# Table name: shipment_supplier_extras
#
#  id          :integer          not null, primary key
#  shipment_id :integer          not null
#  supplier_id :integer          not null
#  field_id    :string           not null
#  value       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_shipment_supplier_extras_on_field_id     (field_id)
#  index_shipment_supplier_extras_on_shipment_id  (shipment_id)
#  index_shipment_supplier_extras_on_supplier_id  (supplier_id)
#
class ShipmentSupplierExtra < ActiveRecord::Base
end
