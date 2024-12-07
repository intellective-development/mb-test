# == Schema Information
#
# Table name: regions
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :text
#  position    :integer          default(0)
#  visible     :boolean          default(FALSE), not null
#  state_id    :integer
#  string      :string(255)
#  slug        :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_regions_on_state_id  (state_id)
#

class Region < ActiveRecord::Base
  extend FriendlyId

  belongs_to :state
  has_many :suppliers, inverse_of: :region
  has_many :cities, inverse_of: :region

  has_one :header_image, class_name: 'Asset', as: :owner, dependent: :destroy
  accepts_nested_attributes_for :header_image,
                                reject_if: proc { |attributes| attributes['file'].nil? },
                                allow_destroy: true

  delegate :name, to: :state, prefix: true

  # TODO: JM: This is unspeakably evil and screws with other scopes, especially distinct or order.
  # .unscoped isn't sufficient as it screws with scopes on associations.
  default_scope { order('regions.position ASC NULLS LAST') }

  friendly_id :slug_candidates, use: %i[slugged finders]

  scope :visible, -> { where(visible: true) }
  scope :hidden,  -> { where(visible: false) }
  scope :for_supplier_ids, ->(supplier_ids) { joins(:suppliers).where(suppliers: { id: supplier_ids }) }

  private

  def slug_candidates
    [
      :name,
      [:name, state&.abbreviation],
      [:name, state&.abbreviation, SecureRandom.uuid[0..4]]
    ]
  end

  def product_ids(ids)
    String(ids).split(',').map(&:to_i)
  end
end
