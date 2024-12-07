# == Schema Information
#
# Table name: cities
#
#  id         :integer          not null, primary key
#  name       :string
#  position   :integer          default(0)
#  visible    :boolean          default(FALSE), not null
#  slug       :string(255)
#  region_id  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_cities_on_region_id  (region_id)
#
# Foreign Keys
#
#  fk_rails_...  (region_id => regions.id)
#

class City < ActiveRecord::Base
  extend FriendlyId

  belongs_to :region
  has_one :state, through: :region

  scope :visible, -> { where(visible: true) }
  scope :sorted, -> { order(name: :asc) }

  has_one :header_image, class_name: 'Asset', as: :owner, dependent: :destroy
  accepts_nested_attributes_for :header_image,
                                reject_if: proc { |attributes| attributes['file'].nil? },
                                allow_destroy: true

  friendly_id :slug_change, use: %i[slugged finders]
end
