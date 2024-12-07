# == Schema Information
#
# Table name: package_after_ship_trackings
#
#  id                     :integer          not null, primary key
#  package_id             :integer
#  after_ship_tracking_id :string(40)       not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_package_after_ship_trackings_on_package_id  (package_id)
#
# Foreign Keys
#
#  fk_rails_...  (package_id => packages.id)
#

class Package::AfterShipTracking < ApplicationRecord
  belongs_to :package, optional: false

  validates :after_ship_tracking_id, presence: true
end
