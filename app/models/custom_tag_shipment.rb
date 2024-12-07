# == Schema Information
#
# Table name: custom_tag_shipments
#
#  id            :integer          not null, primary key
#  custom_tag_id :integer          not null
#  shipment_id   :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_custom_tag_shipments_on_custom_tag_id  (custom_tag_id)
#  index_custom_tag_shipments_on_shipment_id    (shipment_id)
#
class CustomTagShipment < ActiveRecord::Base
  belongs_to :shipment
  belongs_to :custom_tag

  validates :custom_tag_id, uniqueness: { scope: [:shipment_id] }
end
