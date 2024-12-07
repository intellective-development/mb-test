# frozen_string_literal: true

# == Schema Information
#
# Table name: tracking_updates
#
#  id              :bigint(8)        not null, primary key
#  message         :string
#  checkpoint_time :datetime
#  shipment_id     :bigint(8)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_tracking_updates_on_shipment_id  (shipment_id)
#
# Foreign Keys
#
#  fk_rails_...  (shipment_id => shipments.id)
#
class TrackingUpdate < ApplicationRecord
  belongs_to :shipment
end
