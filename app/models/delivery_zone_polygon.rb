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

class DeliveryZonePolygon < DeliveryZone
  before_create :create_json
  before_create :set_geom

  scope :containing, lambda { |address|
    query = "delivery_zones.type = 'DeliveryZonePolygon' AND ST_Contains(ST_GeomFromText(\"delivery_zones\".\"value\", 4326), ST_GeomFromText('POINT(:latitude :longitude)', 4326))"
    where([query, { latitude: address.latitude, longitude: address.longitude }])
  }

  def contains?(address)
    DeliveryZonePolygon.where(id: id).containing(address).any?
  end

  def zipcodes
    {
      fully_contained: DeliveryZonePolygon
        .where(id: id)
        .joins('JOIN zipcode_geoms ON ST_Contains(zipcode_geoms.geom, delivery_zones.geom)')
        .select('delivery_zones.id, JSON_AGG(zipcode_geoms.zcta5ce20) AS zipcodes')
        .group(:id),
      partially_contained: DeliveryZonePolygon
        .where(id: id)
        .joins('JOIN zipcode_geoms ON ST_Overlaps(zipcode_geoms.geom, delivery_zones.geom)')
        .select('delivery_zones.id, JSON_AGG(zipcode_geoms.zcta5ce20) AS zipcodes')
        .group(:id)
    }
  end

  def self.zipcodes(params = {})
    scope = DeliveryZonePolygon.active
                               .joins(shipping_method: :supplier)
                               .where(shipping_methods: { active: true })
    # Filter by search options
    scope = scope.where('suppliers.id = ?', params[:supplier_id])                         if params[:supplier_id]
    scope = scope.where('suppliers.active')                                               if params[:supplier_active_only] == 'true'
    scope = scope.where('zipcode_geoms.zcta5ce20 = ?', params[:zipcode])                  if params[:zipcode]
    scope = scope.where('shipping_methods.shipping_type in (?)', params[:shipping_types]) if params[:shipping_types]&.any?
    scope = scope.where('city_geoms.statefp = ?', params[:state])                         if params[:state]
    scope = scope.where('city_geoms.name ilike ?', "%#{params[:city]}%")                  if params[:city]
    # Complete the query
    scope
      .joins('JOIN zipcode_geoms ON ST_Contains(zipcode_geoms.geom, delivery_zones.geom) OR ST_Overlaps(zipcode_geoms.geom, delivery_zones.geom)')
      .joins('LEFT JOIN city_geoms ON ST_Overlaps(city_geoms.geom, delivery_zones.geom)')
      .select("
zipcode_geoms.zcta5ce20 as zipcode,
ARRAY_REMOVE(ARRAY_AGG(distinct city_geoms.name), NULL) as cities,
ARRAY_REMOVE(ARRAY_AGG(distinct city_geoms.statefp), NULL) as states,
ARRAY_REMOVE(ARRAY_AGG(distinct shipping_methods.shipping_type), NULL) as shipping_types,
ARRAY_REMOVE(ARRAY_AGG(distinct CASE WHEN ST_Contains(zipcode_geoms.geom, delivery_zones.geom) THEN suppliers.name END), NULL) as contained,
ARRAY_REMOVE(ARRAY_AGG(distinct CASE WHEN ST_Overlaps(zipcode_geoms.geom, delivery_zones.geom) THEN suppliers.name END), NULL) as overlapped")
      .group(:zipcode)
  end

  def contained_zipcodes
    scope = DeliveryZonePolygon.where(id: id)
    scope = scope.joins('JOIN zipcode_geoms ON ST_Contains(delivery_zones.geom, zipcode_geoms.geom)')
    scope.select('zipcode_geoms.zcta5ce20 as zipcode').map(&:zipcode)
  end

  def overlapped_zipcodes
    scope = DeliveryZonePolygon.where(id: id)
    scope = scope.joins('JOIN zipcode_geoms ON ST_Overlaps(delivery_zones.geom, zipcode_geoms.geom)')
    scope.select('zipcode_geoms.zcta5ce20 as zipcode').map(&:zipcode)
  end

  # Helper method to return a RGeo polygon based on the value
  def to_geo
    factory = RGeo::Cartesian.factory
    factory.parse_wkt(value)
  end

  # The JSON field contains a GeoJSON formatted blob. This is useful for
  # Periscope and other tools where we want to render delivery zones.
  def create_json
    self.json = RGeo::GeoJSON.encode(to_geo)

    # GeoJSON formates coordinates x, y rather tan y, x (lat, lng) so we need to
    # flip things.
    flipped_coordinates = json['coordinates'][0].map { |c| [c[1], c[0]] }
    json['coordinates'] = [flipped_coordinates]

    self.json = json
  end

  def set_geom
    factory = RGeo::Cartesian.factory(srid: 4326)
    self.geom = factory.parse_wkt(fix_geom_text(value))
  end

  # Extracted from migration 20200923210009_create_zipcode_geom.rb
  def fix_geom_text(geom_as_text)
    geom_as_text
      .sub('POLYGON ((', '').chomp('))') # Remove POLYGON
      .gsub(/([+-]?\d+\.?\d+) ([+-]?\d+\.?\d+)/, '\2 \1') # long lat --> lat long
      .prepend('MULTIPOLYGON (((').concat(')))') # Make it MULTIPOLYGON
  end

  def refresh_zipcode_coverage
    CoverageZipcodesOnDemandRefreshWorker.perform_async
  end
end
