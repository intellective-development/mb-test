# == Schema Information
#
# Table name: shipment_transitions
#
#  id          :integer          not null, primary key
#  to_state    :string(255)      not null
#  metadata    :json
#  sort_key    :integer          not null
#  shipment_id :integer          not null
#  most_recent :boolean          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_shipment_transitions_parent_most_recent  (shipment_id,most_recent) UNIQUE WHERE most_recent
#  index_shipment_transitions_parent_sort         (shipment_id,sort_key) UNIQUE
#

class ShipmentTransition < ActiveRecord::Base
  belongs_to :shipment, inverse_of: :shipment_transitions
end
