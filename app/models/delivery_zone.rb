# == Schema Information
#
# Table name: delivery_zones
#
#  id                 :integer          not null, primary key
#  created_at         :datetime
#  updated_at         :datetime
#  active             :boolean          default(FALSE), not null
#  priority           :boolean          default(FALSE), not null
#  value              :text
#  type               :string(255)
#  shipping_method_id :integer
#  json               :json
#  deleted_at         :datetime
#  geom               :geometry         multipolygon, 4326
#
# Indexes
#
#  idx_delivery_zones_geo                      (st_geomfromtext(value, 4326)) WHERE ((type)::text = 'DeliveryZonePolygon'::text) USING gist
#  index_delivery_zones_on_deleted_at          (deleted_at)
#  index_delivery_zones_on_geom                (geom) USING gist
#  index_delivery_zones_on_id_and_type         (id,type)
#  index_delivery_zones_on_shipping_method_id  (shipping_method_id)
#  ix_delivery_zones_on_state                  (value) WHERE ((type)::text = 'DeliveryZoneState'::text)
#

class DeliveryZone < ActiveRecord::Base
  DELIVERY_ZONE_TYPES = %w[DeliveryZonePolygon DeliveryZoneState].freeze

  has_paper_trail ignore: %i[created_at updated_at]
  acts_as_paranoid

  belongs_to :shipping_method, touch: true

  validates :value, presence: true
  validates :type,  presence: true

  after_create :refresh_zipcode_coverage, if: -> { active }
  after_update :refresh_zipcode_coverage, if: :saved_change_to_active?

  scope :containing, lambda { |address|
    state_zone_ids = DeliveryZoneState.containing(address).pluck(:id)
    polygon_zone_ids = DeliveryZonePolygon.containing(address).pluck(:id)
    where(id: polygon_zone_ids | state_zone_ids)
  }
  scope :active,    -> { where(active: true) }
  scope :inactive,  -> { where(active: false) }
  scope :supplier_shipping_active, lambda {
    includes(shipping_method: :supplier)
      .where(shipping_method: { active: true })
      .where(shipping_method: { supplier: { active: true } })
  }

  delegate :supplier, to: :shipping_method, allow_nil: true
  delegate :supplier_id, to: :shipping_method, allow_nil: true

  # Priority zones take precidence if multiple zones are selected.
  scope :priority,  -> { where(priority: true) }
  scope :polygons,  -> { where(type: 'DeliveryZonePolygon') }
  scope :states,    -> { where(type: 'DeliveryZoneState') }

  def contains?(_address)
    # This should never be called since real delivery zones should be
    # an instance of this.
    false
  end
end
