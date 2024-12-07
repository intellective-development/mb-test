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

class DeliveryZoneState < DeliveryZone
  STATES = [
    %w[Alabama AL 01],
    %w[Alaska AK 02],
    %w[Arizona AZ 04],
    %w[Arkansas AR 05],
    %w[California CA 06],
    %w[Colorado CO 08],
    %w[Connecticut CT 09],
    %w[Delaware DE 10],
    %w[Florida FL 12],
    %w[Georgia GA 13],
    %w[Hawaii HI 15],
    %w[Idaho ID 16],
    %w[Illinois IL 17],
    %w[Indiana IN 18],
    %w[Iowa IA 19],
    %w[Kansas KS 20],
    %w[Kentucky KY 21],
    %w[Louisiana LA 22],
    %w[Maine ME 23],
    %w[Maryland MD 24],
    %w[Massachusetts MA 25],
    %w[Michigan MI 26],
    %w[Minnesota MN 27],
    %w[Mississippi MS 28],
    %w[Missouri MO 29],
    %w[Montana MT 30],
    %w[Nebraska NE 31],
    %w[Nevada NV 32],
    ['New Hampshire', 'NH', '33'],
    ['New Jersey', 'NJ', '34'],
    ['New Mexico', 'NM', '35'],
    ['New York', 'NY', '36'],
    ['North Carolina', 'NC', '37'],
    ['North Dakota', 'ND', '38'],
    %w[Ohio OH 39],
    %w[Oklahoma OK 40],
    %w[Oregon OR 41],
    %w[Pennsylvania PA 42],
    ['Rhode Island', 'RI', '44'],
    ['South Carolina', 'SC', '45'],
    ['South Dakota', 'SD', '46'],
    %w[Tennessee TN 47],
    %w[Texas TX 48],
    %w[Utah UT 49],
    %w[Vermont VT 50],
    %w[Virginia VA 51],
    %w[Washington WA 53],
    ['West Virginia', 'WV', '54'],
    %w[Wisconsin WI 55],
    %w[Wyoming WY 56],
    ['American Samoa', 'AS', '60'],
    %w[Guam GU 66],
    ['Northern Mariana Islands', 'MP', '69'],
    ['Puerto Rico', 'PR', '72'],
    ['Virgin Islands', 'VI', '78']
  ].freeze
  NAMES = STATES.each_with_object({}) { |(name, postal_code, fips), acc| acc[fips] = "#{name} (#{postal_code})" }
  CODES = STATES.each_with_object({}) { |(_name, postal_code, fips), acc| acc[fips] = postal_code }
  FIPS  = STATES.each_with_object({}) { |(_name, postal_code, fips), acc| acc[postal_code] = fips }

  scope :containing, lambda { |address|
    where(value: String(address.state_name).upcase)
  }

  def self.zipcodes(params = {})
    scope = DeliveryZoneState.active
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
      .joins("JOIN city_geoms ON city_geoms.statefp = (select d.value FROM json_each_text('#{FIPS.to_json}'::json) as d where d.key = delivery_zones.value)")
      .joins('JOIN zipcode_geoms ON ST_Contains(city_geoms.geom, zipcode_geoms.geom) OR ST_Overlaps(city_geoms.geom, zipcode_geoms.geom)')
      .select("
zipcode_geoms.zcta5ce20 as zipcode,
ARRAY_REMOVE(ARRAY_AGG(distinct city_geoms.name), NULL) as cities,
ARRAY_REMOVE(ARRAY_AGG(distinct city_geoms.statefp), NULL) as states,
ARRAY_REMOVE(ARRAY_AGG(distinct shipping_methods.shipping_type), NULL) as shipping_types,
ARRAY_REMOVE(ARRAY_AGG(distinct suppliers.name), NULL) as contained,
null as overlapped")
      .group(:zipcode)
  end

  def self.contained_zipcodes(params = {})
    # returns only completely covered zipcodes
    scope = DeliveryZoneState.active
                             .joins(shipping_method: :supplier)
                             .where(shipping_methods: { active: true })
    scope = scope.where('zipcode_geoms.zcta5ce20 in (?)', params[:zipcodes]) if params[:zipcodes]
    scope
      .joins("JOIN city_geoms ON city_geoms.statefp = (select d.value FROM json_each_text('#{FIPS.to_json}'::json) as d where d.key = delivery_zones.value)")
      .joins('JOIN zipcode_geoms ON ST_Contains(city_geoms.geom, zipcode_geoms.geom)')
      .select('zipcode_geoms.zcta5ce20 as zipcode')
  end

  def contains?(address)
    String(address.state_name).casecmp(String(value)).zero?
  end

  def refresh_zipcode_coverage
    CoverageZipcodesShippedRefreshWorker.perform_async
  end
end
