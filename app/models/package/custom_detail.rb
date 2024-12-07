# == Schema Information
#
# Table name: package_custom_details
#
#  id                  :integer          not null, primary key
#  package_id          :integer
#  tracking_url        :string
#  package_description :string
#  package_external_id :string
#  status              :string
#
# Indexes
#
#  index_package_custom_details_on_package_id  (package_id)
#
# Foreign Keys
#
#  fk_rails_...  (package_id => packages.id)
#

class Package::CustomDetail < ActiveRecord::Base
  belongs_to :package, optional: false
  self.table_name = :package_custom_details

  validates :package_id, presence: true
end
