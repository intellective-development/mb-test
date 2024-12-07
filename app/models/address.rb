# == Schema Information
#
# Table name: addresses
#
#  id                        :integer          not null, primary key
#  name                      :string(255)
#  company                   :string(255)
#  addressable_type          :string(255)      not null
#  addressable_id            :integer          not null
#  address1                  :string(255)      not null
#  address2                  :string(255)
#  city                      :string(255)      not null
#  state_id                  :integer
#  state_name                :string(255)
#  zip_code                  :string(255)      not null
#  phone                     :string(255)
#  email                     :string(255)
#  alternative_phone         :string(255)
#  notes                     :text
#  default                   :boolean          default(FALSE), not null
#  billing_default           :boolean          default(FALSE), not null
#  active                    :boolean          default(TRUE), not null
#  created_at                :datetime
#  updated_at                :datetime
#  country_id                :integer
#  latitude                  :float
#  longitude                 :float
#  geocoded_at               :datetime
#  override_latitude         :float
#  override_longitude        :float
#  trak_id                   :string(255)
#  address_purpose           :integer
#  doorkeeper_application_id :integer
#  normalized_phone          :string
#  storefront_address_id     :string
#  storefront_id             :integer
#
# Indexes
#
#  index_addresses_on_addressable_id_and_addressable_type  (addressable_id,addressable_type)
#  index_addresses_on_addressable_type                     (addressable_type)
#  index_addresses_on_state_id                             (state_id)
#  index_addresses_on_storefront_id                        (storefront_id)
#  index_addresses_on_zip_code                             (zip_code)
#
# Foreign Keys
#
#  fk_rails_...  (storefront_id => storefronts.id)
#

class Address < ActiveRecord::Base
  include Address::SegmentSerializer
  include BarOS::Cache::PreSales

  # attributes that are non user specific
  SANITARY_ATTRS = %i[addressable_type addressable_id address1 address2 city state_id state_name zip_code active country_id latitude longitude geocoded_at override_latitude override_longitude address_purpose].freeze

  DIRECTIONAL_TRANSLATIONS = {
    'north' => 'N',
    'northeast' => 'NE',
    'east' => 'E',
    'southeast' => 'SE',
    'south' => 'S',
    'southwest' => 'SW',
    'west' => 'W',
    'northwest' => 'NW'
  }.freeze

  auto_strip_attributes :name, :company, :address1, :address2, :city, :state_name, :phone, squish: true

  enum address_purpose: {
    shipping: 0,
    billing: 1,
    supplier: 2,
    cart_share: 3
  }

  attr_accessor :replace_address_id # if you are updating an address set this field.

  alias_attribute :delivery_notes, :notes

  has_paper_trail

  belongs_to :addressable, polymorphic: true
  belongs_to :country
  belongs_to :doorkeeper_application, class_name: 'Doorkeeper::Application'
  belongs_to :state
  belongs_to :storefront, optional: true

  has_many :shipments
  has_many :orders, foreign_key: 'ship_address_id'
  has_one :payment_profile

  geocoded_by :full_street_address, lookup: ->(obj) { obj.geocoder_lookup }

  validates :name,            presence: true, length: { maximum: 255 }
  validates :company,         length: { maximum: 255 }
  validates :address1,        presence: true, length: { maximum: 255 }
  validates :city,            presence: true,
                              format: { with: CustomValidators::Names.name_validator },
                              length: { maximum: 75 }
  validates :country_id,      presence: true, if: proc { |_address| Settings.require_country_in_address }
  validates :zip_code,        presence: true, length: { minimum: 5, maximum: 12 }
  validates :address_purpose, presence: true

  phony_normalize :phone, as: :normalized_phone

  # Temporarily disabled as causing issues with iOS - when a user is logged in the app tries to
  # save addresses entered via. Google Places immediately rather than checking for suppliers and
  # waiting until customer is in checkout. Since this address has no phone number the resulting API
  # error was preventing logged in users from selecting new addresses.
  #
  #  validates :phone,       presence: true, if: :shipping?

  after_validation :geocode, if: ->(obj) { obj.materially_changed? || !obj.recently_geocoded? }

  before_create :default_to_active
  before_create :set_city_from_zip
  before_create :set_state_name_from_zip
  before_create :set_state_id
  before_save :set_geocoded_at
  before_update :set_state_id, if: :state_name_changed?
  after_commit :replace_address, if: :replace_address_id
  after_commit :replace_old_defaults, if: -> { user_address? && default? }
  after_commit :replace_old_billing_defaults, if: -> { user_address? && billing_default? }
  after_commit :update_bar_os_pre_sale_cache

  #----------------------------------------------------------------------
  # Scopes
  #----------------------------------------------------------------------
  scope :active,      -> { where(active: true) }
  scope :shipping,    -> { where(addressable_type: 'User', address_purpose: Address.address_purposes[:shipping]) }
  scope :supplier,    -> { where(addressable_type: 'Supplier', address_purpose: Address.address_purposes[:supplier]) }
  scope :ungeocoded,  -> { where(latitude: nil, longitude: nil) }
  scope :within_zipcodes, ->(zipcodes) { where(zip_code: zipcodes) }
  scope :within_delivery_zone, lambda { |delivery_zone_id|
    joins("INNER JOIN delivery_zones on delivery_zones.id = #{delivery_zone_id}")
      .where('ST_Contains(delivery_zones.geom, ST_SetSRID(ST_MakePoint(addresses.longitude, addresses.latitude), 4326)) = true')
  }

  # This ordering is used by the API when returning a users addresses - in cases such as
  # Alexa the client is using the first item in the array, so we are ensuring that
  # this is always the default address for the application in question.
  scope :ordered_by_client, ->(id) { order("CASE addresses.doorkeeper_application_id WHEN #{id} THEN 1 ELSE 2 END ASC").order(default: :desc).order(updated_at: :desc) }
  scope :ordered_by_most_recent, -> { order(updated_at: :desc) }
  scope :order_by_client_recency, ->(id) { joins('LEFT OUTER JOIN orders on orders.ship_address_id = addresses.id').order(Arel.sql("CASE addresses.doorkeeper_application_id WHEN #{id} THEN 1 ELSE 2 END ASC")).order(default: :desc).order('orders.completed_at DESC NULLS LAST') }
  scope :order_by_recently_used, -> { joins('LEFT OUTER JOIN orders on orders.ship_address_id = addresses.id').order('orders.completed_at DESC NULLS LAST') }

  def validate_for_ongoing_orders
    ongoing_orders = Order.joins(:shipments).where(ship_address_id: id).where.not(state: nil, completed_at: nil, shipments: { state: :delivered }).distinct(:id)
    return true if ongoing_orders.blank?

    ongoing_orders.each do |order|
      order.variants.each do |variant|
        trait = variant.product.product_trait
        no_ship = trait&.ship_category_model&.no_ship_state&.states
        errors.add(:state_name, :no_ship_state, message: 'The state is registered as non-shippable') if no_ship&.include?(state_name)

        ships = variant.supplier&.supplier_ship_states&.pluck(:states)&.flatten
        errors.add(:state_name, :supplier_ship_state, message: 'The state is not supported by the supplier') if ships.blank? || ships.exclude?(state_name)

        return false if errors[:state_name]&.any? # avoid duplicated error messages
      end
    end
  end

  #-----------------------------------
  # Class methods
  #-----------------------------------
  def self.create_from_params(params)
    if params[:aid].present? || params[:address_id].present?
      find_by(id: params[:aid] || params[:address_id])
    elsif params[:coords].present?
      coords = {
        lat: params[:coords][:lat] || params[:coords][:latitude],
        lng: params[:coords][:lng] || params[:coords][:longitude]
      }

      new(longitude: coords[:lng],
          latitude: coords[:lat],
          state_name: params.dig(:address, :state) || [coords[:lat], coords[:lng]].to_zip&.to_region(state: true),
          address_purpose: :shipping)
    elsif params[:address].present?
      new(address1: URI.decode(normalize_directional_components(String(params[:address][:address1]))),
          address2: URI.decode(String(params[:address][:address2])),
          city: URI.decode(String(params[:address][:city])),
          state_name: URI.decode(String(params[:address][:zip_code])).to_region(state: true),
          zip_code: URI.decode(String(params[:address][:zip_code])),
          address_purpose: :shipping)
    end
  end

  def self.normalize_directional_components(string)
    # In practice Google's geocoder has issues with directional components,
    # often returning the wrong result in cases for non-abbreviated strings.
    String(string).gsub(/[[:word:]]+/).each do |word|
      DIRECTIONAL_TRANSLATIONS[word.downcase] || word
    end
  end

  def self.update_address(old_address, params)
    new_address = old_address.dup
    new_address.assign_attributes(params)
    new_address.replace_address_id = old_address.id

    # NOTE: NO CLUE WHERE THIS IS HAPPENIGN
    # BUT WE SHOULD REUSE LAT/LNG FROM WEB
    # THIS IS FOR MAKING SURE WE DONT REUSE LAT/LNG FROM OLD ADDRESS
    new_address.latitude = nil
    new_address.longitude = nil

    if new_address.save
      old_address.deactivate
      new_address
    end
  end

  #----------------------------------------------------------------------
  # Instance methods
  #----------------------------------------------------------------------
  def dup_sanitized
    sanitary_attrs = attributes.symbolize_keys.slice(*SANITARY_ATTRS)
    Address.new(sanitary_attrs)
  end

  def probable_state_id
    State.lookup_state_id(state_name)
  end

  def business?
    company.present?
  end

  def deactivate
    update(active: false)
  end

  def available_shipping_methods
    location_services.shipping_methods
  end

  def available_shipping_methods_by_supplier_type
    collection = available_shipping_methods.group_by { |shipping_method| shipping_method.supplier.supplier_type.name.parameterize.to_sym }

    collection.each { |type, methods| collection[type] = methods.map(&:shipping_type).uniq }
  end

  def shipping_only?
    grouped_shipping_methods = available_shipping_methods_by_supplier_type

    grouped_shipping_methods.key?(:'wine-spirits') && grouped_shipping_methods[:'wine-spirits'] == ['shipped']
  end

  def dtc_only?
    grouped_shipping_methods = available_shipping_methods_by_supplier_type

    grouped_shipping_methods.key?(:'vineyard-select') && !grouped_shipping_methods.key?(:'wine-spirits') &&
      !grouped_shipping_methods.key?(:'beer-mixers')
  end

  def all_suppliers
    location_services.find_suppliers
  end

  def supplier
    ls = LocationServices.new(self, select_multiple_suppliers: false)
    ls.find_suppliers
  end

  def trak?
    trak_id.present?
  end

  def full_address_array
    [name, address1, address2, city_state_zip].compact
  end

  def state_abbr_name
    state ? state.abbreviation : state_name
  end

  def city_state_name
    [city, state_abbr_name].join(', ')
  end

  def full_street_address
    [address1, address2, city_state_zip].compact.join(', ')
  end

  def name_line
    [name, company].compact.join(' - ')
  end

  # Use this method to represent the full address as an array compacted
  #
  # @param [Optional String] default is ', '
  # @return [String] address1 and address2 joined together with the string you pass in
  def address_lines(join_chars = ', ')
    address_lines_array.join(join_chars)
  end

  def address_lines_array
    [address1, address2].delete_if(&:blank?)
  end

  # Use this method to represent the "city, state.abbreviation zip_code"
  #
  # @param [none]
  # @return [String] "city, state.abbreviation zip_code"
  def city_state_zip
    [city_state_name, zip_code].join(' ')
  end

  def geocodable?
    !geocode_failed? && (zip_code.present? && zip_code.length == 5) || (latitude.present? && longitude.present?)
  end

  def geocoded?
    (latitude.present? && longitude.present?) || geocode_override?
  end

  def geocode_override?
    override_latitude.present? && override_longitude.present?
  end

  def geocode_failed?
    geocoded_at && (longitude.nil? || latitude.nil?)
  end

  def latitude
    override_latitude || attributes['latitude']
  end

  def longitude
    override_longitude || attributes['longitude']
  end

  def recently_geocoded?
    geocoded_at && geocoded_at > 14.days.ago
  end

  def materially_changed?
    address1_changed? || city_changed? || state_name_changed? || zip_code_changed?
  end

  def geocoder_lookup
    return :test if Rails.env.test?

    # Currently we default to Google, but have the option to use Bing's geocoder
    # in the event of an outage.
    Feature[:bing_geocoder].enabled? ? :bing : :google
  end

  alias original_geocode geocode
  def geocode
    # We will skip geocode when we send lat/long from frontend
    # Avoids double-call to google + we have the user-selected lat/long
    original_geocode unless geocoded_at.present? && new_record? && latitude.present? && longitude.present?
  end

  def geocode!
    geocode
    set_geocoded_at
    save

    if geocode_failed?
      Rails.logger.error("Unable to geocode address id #{id}: #{full_street_address}")
      fallback_geocode!
    end
  end

  def fallback_geocode!
    return if geocoded?

    begin
      update(override_latitude: zip_code.to_lat, override_longitude: zip_code.to_lon)
    rescue StandardError
      nil
    end
    if override_latitude.nil? || override_longitude.nil?
      Rails.logger.error("Unable to fallback geocode address id #{id}: #{zip_code}")
    else
      set_geocoded_at
    end
  end

  def blacklisted_by_alert?
    AddressBlacklist.blacklisted_by_alert?(self)
  end

  def blacklisted_by_block?
    AddressBlacklist.blacklisted_by_block?(self)
  end

  def anonymize
    if user_address?
      update(
        email: addressable.email,
        name: addressable.name,
        phone: "#{rand(100..999)}-#{rand(100..999)}-#{rand(1000..9999)}",
        address1: '111 Noplace'
      )
    end
  end

  def update_bar_os_pre_sale_cache
    return unless addressable_type == Supplier.name && SupplierProductOrderLimit.exists?(supplier_id: addressable_id)

    update_bar_os_pre_sale_cache_async
  end

  private

  def location_services
    @location_services ||= LocationServices.new(self, select_multiple_suppliers: true)
  end

  def set_geocoded_at
    self.geocoded_at = Time.zone.now
  end

  def default_to_active
    self.active ||= true
  end

  def user_address?
    addressable_type == 'User'
  end

  def replace_address
    Address.where(id: replace_address_id).update_all(active: false)
  end

  def replace_old_defaults
    addressable.addresses.where.not(id: id).where(doorkeeper_application: doorkeeper_application).update_all(default: false)
  end

  def replace_old_billing_defaults
    addressable.addresses.where.not(id: id).update_all(billing_default: false)
  end

  def set_state_name_from_zip
    return unless state_name.blank? && zip_code

    probable_state_name = zip_code.to_region(state: true)
    self.state_name = probable_state_name if probable_state_name
  end

  def set_city_from_zip
    return unless city.blank? && zip_code

    probable_city = zip_code.to_region(city: true)
    self.city = probable_city if probable_city
  end

  def set_state_id
    probable_id = probable_state_id
    self.state_id = probable_id if probable_id
  end
end
