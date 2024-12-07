# == Schema Information
#
# Table name: package_ship_engine_details
#
#  id                      :integer          not null, primary key
#  package_id              :integer
#  ship_engine_shipment_id :string(40)
#  ship_engine_label_id    :string(40)
#  dimensions              :hstore
#  weight                  :hstore
#  confirmation            :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_package_ship_engine_details_on_package_id  (package_id)
#
# Foreign Keys
#
#  fk_rails_...  (package_id => packages.id)
#

class Package::ShipEngineDetail < ApplicationRecord
  CONFIRMATION_TYPES = %w[none delivery signature adult_signature direct_signature delivery_mailed].freeze

  belongs_to :package, optional: false

  validates :confirmation, :dimensions, :weight, presence: true
  validates :confirmation, inclusion: { in: CONFIRMATION_TYPES }

  def dimensions=(value)
    raise ArgumentError.new, "Dimensions should contain 'length', 'width' and 'height' keys" unless %i[length width height].all? { |key| Hash(value).key?(key) }

    super(value)
  end

  def weight=(value)
    raise ArgumentError.new, "Weight should contain 'value' and 'unit' keys" unless %i[value unit].all? { |key| Hash(value).key?(key) }

    super(value)
  end
end
