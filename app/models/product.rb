# == Schema Information
#
# Table name: products
#
#  id                      :integer          not null, primary key
#  name                    :string(255)      not null
#  prototype_id            :integer
#  permalink               :string(255)      not null
#  deleted_at              :datetime
#  featured                :boolean          default(FALSE), not null
#  created_at              :datetime
#  updated_at              :datetime
#  item_volume             :string(255)
#  upc                     :string(255)
#  quality_score           :integer          default(0)
#  cached_hierarchy        :string(255)
#  tax_category_id         :integer
#  wine_apis_accessed      :boolean          default(FALSE), not null
#  state                   :string(255)
#  volume_unit             :string(255)
#  volume_value            :decimal(, )
#  container_type          :string(255)
#  container_count         :integer
#  upc_ext                 :string(8)
#  apis_accessed           :string(255)      default([]), is an Array
#  searchable              :boolean          default(TRUE), not null
#  product_grouping_id     :integer
#  short_pack_size         :string(255)
#  short_volume            :string(255)
#  additional_upcs         :string(510)      default([]), is an Array
#  mechant_sku             :string
#  search_volume           :string(255)
#  storefront_availability :jsonb
#  default_search_hidden   :boolean          default(FALSE)
#  tax_code                :string
#  allows_back_order       :boolean          default(TRUE)
#  max_quantity_per_order  :integer
#  pre_engraved_message    :string
#  master                  :boolean          default(FALSE)
#  limited_time_offer      :boolean          default(FALSE)
#  limited_time_offer_data :jsonb
#  liquid                  :boolean
#  liquid_id               :string
#
# Indexes
#
#  index_products_on_additional_upcs      (additional_upcs) USING gin
#  index_products_on_liquid_id            (liquid_id) UNIQUE WHERE (liquid_id IS NOT NULL)
#  index_products_on_liquid_id_and_state  (liquid_id) WHERE ((state)::text = 'active'::text)
#  index_products_on_mechant_sku          (mechant_sku)
#  index_products_on_name                 (name)
#  index_products_on_permalink            (permalink) UNIQUE
#  index_products_on_product_grouping_id  (product_grouping_id)
#  index_products_on_upc                  (upc)
#
class Product < ActiveRecord::Base
  extend FriendlyId
  include ProductPriorityScope
  include Products::SearchScope
  include Products::LimitedTimeOffer

  # Annotations are internal facing, used to annotate the product. (e.g. "Image not found")
  acts_as_taggable_on :annotations

  auto_strip_attributes :name, :item_volume, :upc, :volume_unit, :container_type, squish: true

  friendly_id :permalink_candidates, use: %i[slugged finders history], slug_column: :permalink
  # This is required due to the following issues in friendly_id 5.2.0
  # https://github.com/norman/friendly_id/issues/765
  alias_attribute :slug, :permalink

  attr_accessor :product_subtype_id, :uuid, :trusted

  belongs_to :product_size_grouping, foreign_key: :product_grouping_id
  belongs_to :prototype
  belongs_to :tax_category

  has_many :source_merges,      -> { where(mergeable_type: 'Product') }, class_name: 'ProductMerge', foreign_key: :source_id
  has_many :destination_merges, -> { where(mergeable_type: 'Product') }, class_name: 'ProductMerge', foreign_key: :destination_id

  has_many :product_properties, as: :product, dependent: :destroy, inverse_of: :product
  has_many :properties, through: :product_properties
  has_many :variants, inverse_of: :product
  has_many :order_items, through: :variants, inverse_of: :product
  has_many :images, -> { order(:position) }, as: :imageable, dependent: :destroy
  has_many :active_variants, -> { where(deleted_at: nil) }, class_name: 'Variant'

  has_one :brand,              through: :product_size_grouping
  has_one :hierarchy_category, through: :product_size_grouping, class_name: 'ProductType'
  has_one :hierarchy_subtype,  through: :product_size_grouping, class_name: 'ProductType'
  has_one :hierarchy_type,     through: :product_size_grouping, class_name: 'ProductType'
  has_one :product_content,    through: :product_size_grouping
  has_one :product_type,       through: :product_size_grouping
  has_one :product_trait

  accepts_nested_attributes_for :images,              reject_if: proc { |t| (t['photo'].nil? && t['photo_from_link'].blank?) }, allow_destroy: true
  accepts_nested_attributes_for :product_properties,  reject_if: proc { |attributes| attributes['description'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :variants,            reject_if: proc { |attributes| attributes['supplier_id'].blank? || attributes['sku'].blank? }, allow_destroy: true
  accepts_nested_attributes_for :product_size_grouping, update_only: true, allow_destroy: false

  validates :name, presence: true, length: { maximum: 255 }
  validates :permalink, length: { maximum: 255 }
  validates :upc, upc: true, allow_nil: true, uniqueness: { scope: :upc_ext, allow_nil: true }
  validate :check_active_pre_sale, on: :update, if: :state_changed?

  before_validation :not_active_on_create!, on: :create
  after_create :create_grouping

  before_save :validate_volume
  before_save :update_item_volume_cache
  before_save :set_prototype
  before_save :reset_apis_flag
  before_save :ensure_search_volume

  after_update :activate_inactive_variants, if: -> { Feature[:limited_time_offer_feature].enabled? && limited_time_offer_previously_changed? && !limited_time_offer }

  after_commit -> { reindex_async(true) }

  # delegate :name,             to: :product_size_grouping, allow_nil: false, prefix: false
  delegate :description,      to: :product_size_grouping, allow_nil: true
  delegate :meta_description, to: :product_size_grouping, allow_nil: true
  delegate :meta_keywords,    to: :product_size_grouping, allow_nil: true
  delegate :tag_list,         to: :product_size_grouping, allow_nil: true
  delegate :name, to: :brand,               allow_nil: true, prefix: true
  delegate :name, to: :hierarchy_category,  allow_nil: true, prefix: true
  delegate :name, to: :hierarchy_subtype,   allow_nil: true, prefix: true
  delegate :name, to: :hierarchy_type,      allow_nil: true, prefix: true
  delegate :name, to: :product_type,        allow_nil: true, prefix: true
  delegate :name, to: :prototype,           allow_nil: true, prefix: true
  delegate :permalink, to: :product_size_grouping, allow_nil: true, prefix: true

  scope :visible, lambda {
    joins(:product_size_grouping)
      .where('product_groupings.product_type_id NOT IN (?)', [ProductType.find_by(name: ProductType::UNIDENTIFIED_TYPE).try(:id), ProductType.find_by(name: ProductType::HIDDEN_TYPE).try(:id)])
  }
  scope :where_identifier, lambda { |identifiers|
    permalinks = Array(identifiers).select { |id| id.is_a?(String) }
    ids = Array(identifiers).select { |id| id.is_a?(Numeric) }
    permalinks += Product.where(id: ids).pluck(:permalink)
    Product.where(id: FriendlyId::Slug.where(sluggable_type: 'Product', slug: permalinks.uniq).pluck(:sluggable_id))
  }

  scope :active,              -> { where(state: 'active') }
  scope :active_or_pending,   -> { where(state: %w[active pending]) }
  # TODO: These are awful on 2 levels, .find_by when only id is used. Could merge scopes instead. And type.try is gross.
  scope :all_of_type,         ->(type) { descendent_of_type(ProductType.find_by(name: type)) }
  scope :descendent_of_type,  ->(type) { joins(:product_size_grouping).where(product_groupings: { product_type_id: type&.descendent_ids }) }
  scope :of_type,             ->(type) { joins(:product_size_grouping).where(product_groupings: { product_type_id: type&.id }) }
  scope :inactive,            -> { where(state: 'inactive') }
  scope :inactive_or_pending, -> { where(state: %w[inactive pending]) }
  scope :countable,           -> { where.not(state: %w[merged inactive]) }
  scope :pending,             -> { where(state: 'pending') }
  scope :flagged,             -> { where(state: 'flagged') }
  scope :merged,              -> { where(state: 'merged') }
  scope :not_merged,          -> { where.not(state: 'merged') }
  scope :sold_by,             ->(supplier_id) { joins(:variants).where(variants: { supplier_id: supplier_id }).uniq }

  # Converted methods
  scope :product_type_filter, ->(product_type_id) { joins(:product_size_grouping).where(product_type_id: product_type_id) }
  scope :brand_id_filter,     ->(brand_id) { joins(:product_size_grouping).where(brand_id: brand_id) }
  scope :name_filter,         ->(name) { where('lower(products.name) LIKE lower(?)', "#{name}%") }
  scope :inactive_filter,     ->(show_inactive) { show_inactive ? self : active_or_pending }

  state_machine initial: 'pending' do
    state 'inactive'
    state 'pending'
    state 'active'
    state 'flagged'
    state 'merged'

    before_transition to: 'active',  do: [:ready_for_activation?]
    after_transition to: 'inactive', do: [:deactivate_self_and_variants!]
    after_transition to: 'flagged',  do: [:deactivate_self_and_variants!]
    after_transition to: 'pending',  do: [:deactivate_self_and_variants!] # shouldn't happen, in case it does
    after_transition to: 'active',   do: [:activate_self_and_variants!]

    event :deactivate do
      transition to: 'inactive', from: %w[pending active flagged]
    end
    event :pend do
      transition to: 'pending', from: %w[inactive active flagged]
    end
    event :activate do
      transition to: 'active', from: %w[inactive pending flagged]
    end
    event :flag do
      transition to: 'flagged', from: %w[inactive pending active]
    end
    event :merge do
      transition to: 'merged', from: %w[active inactive flagged pending]
    end
  end

  #-----------------------------------------------------
  # SearchKick methods
  #-----------------------------------------------------
  scope :search_import, -> { includes([{ variants: %i[supplier inventory] }, :product_type, :brand]) }

  searchkick callbacks: false,
             index_name: -> { "#{name.tableize}_#{ENV['SEARCHKICK_SUFFIX'] || ENV['RAILS_ENV']}" },
             batch_size: 200,
             searchable: %i[id name brand item_volume full_name upc],
             text_middle: %i[name item_volume upc] # Partial matching

  def should_index?
    state != 'merged'
  end

  def search_hidden?
    (!product_size_grouping.nil? &&
      product_size_grouping.search_hidden?) ||
      default_search_hidden?
  end

  def search_data
    variants_count = variants.self_active.count

    as_json only: [:id]
    {
      id: id,
      active: active?,
      brand: brand_name,
      item_volume: item_volume,
      in_stock: has_stock?,
      in_stock_supplier: variants.self_active.available.pluck(:supplier_id),
      name: name,
      full_name: get_full_name,
      state: state,
      upc: upc,
      suppliers: variants.pluck(:supplier_id),
      category: hierarchy_category_name,
      type: hierarchy_type_name,
      subtype: hierarchy_subtype_name,
      searchable: product_type&.searchable? && searchable?,
      search_hidden: search_hidden?,
      has_image: has_images?,
      has_grouping_image: has_grouping_image?,
      variant_count: variants_count, # This may include pending
      merged_count: destination_merges.count,
      has_variants: variants_count.positive?, # Include pending too (used to find candidates to merge)
      merchant_sku: mechant_sku,
      master: master
    }
  end

  #-----------------------------------------------------
  # Class methods
  #-----------------------------------------------------
  def self.parse_product_id(id)
    return nil if id.blank?

    /^\d+$/.match?(id) ? id : Product.where_identifier(id).first&.id
  end

  def self.parse_product_ids(product_ids)
    product_ids.map do |id|
      parse_product_id(id)
    end.compact
  end

  #-----------------------------------------------------
  # Instance methods
  #-----------------------------------------------------
  def mergeable?
    active? || pending? || inactive? || flagged?
  end

  def deactivate_self_and_variants!
    update_attribute(:deleted_at, Time.zone.now)
    variants.update_all(product_active: false)
  end

  def activate_self_and_variants!
    update_attribute(:deleted_at, nil)
    clean_limited_time_offer_data
    variants.update_all(product_active: true)
    log_activation
  end

  def ready_for_activation?
    return true if active?

    valid?
    errors.add(id.to_s, 'product type is not valid') unless Product.visible.exists?(id)
    errors.add(id.to_s, 'All variants should have price') unless variants.all? { |v| v.price >= 0.0 }
    errors.any? ? false : true
  end

  def search_keywords
    (product_type ? product_type.keywords : []).to_a
  end

  def get_full_name
    "#{name} #{item_volume}"
  end

  def validate_volume
    # function before save to informally validate volume information
    root = hierarchy_category&.name
    if %w[wine liquor].include? root
      if root == 'wine' && volume_unit.nil? && volume_value.nil?
        self.volume_unit = 'ML'
        self.volume_value = 750.0
      elsif volume_unit && volume_value && String(volume_unit).casecmp('ML').zero? && Float(volume_value) >= 1000.0
        self.volume_unit = 'L'
        self.volume_value = Float(volume_value) / 1000.0
      elsif volume_unit && volume_value && String(volume_unit).casecmp('L').zero? && Float(volume_value) < 1.0
        self.volume_unit = 'ML'
        self.volume_value = Float(volume_value) * 1000.0
      end
      if container_count.nil? && container_type.nil?
        self.container_type = 'BOTTLE'
        self.container_count = 1
      end
    elsif root == 'beer'
      if container_count == 6 && volume_value.nil? && volume_unit.nil?
        self.volume_value = 12.0
        self.volume_unit = 'OZ'
      end
    end
  end

  # These are the volume values which should be used on API responses and in
  # the UI. This keeps structure and formatting consistent.
  #
  #   item_volume     - The complete volume string (eg. 12 pack, 12oz bottles)
  #   short_pack_size - Just the pack size (eg. 12 pack). For single items this
  #                     will be an empty string.
  #   short_volume    - Just the volume and unit (eg. 750ml)
  def update_item_volume_cache
    self.item_volume     = humanize_item_volume
    self.short_pack_size = humanize_pack_size
    self.short_volume    = humanize_volume
  end

  def set_prototype
    self.prototype = Prototype.find_by(name: hierarchy_category_name)
  end

  def type_hierarchy
    [hierarchy_category, hierarchy_type, hierarchy_subtype].compact
  end

  def kosher?
    !get_property('kosher').nil?
  end

  def uncache_image_keys
    PAPERCLIP_STORAGE_OPTS[:styles].each_pair do |image_size, _|
      Rails.cache.delete("Product-featured_image-#{id}-#{image_size}")
      Rails.cache.delete("Product-image_urls-#{id}-#{image_size}")
    end
    Rails.cache.delete(namespace: "Product-featured_image-#{id}")
  end

  def has_images?(force: false)
    return @has_images if defined?(@has_images) && !force

    @has_images = images.exists?
  end

  def has_grouping_image?
    return false unless product_size_grouping

    product_size_grouping.images.exists?
  end

  def has_stock?
    variants.self_active.available.exists?
  end

  def featured_image(image_size = :small)
    Rails.cache.fetch("Product-featured_image-#{id}:#{has_images?}:#{product_size_grouping.updated_at}:#{updated_at}-#{image_size}",
                      namespace: "Product-featured_image-#{id}",
                      expires_in: 4.hours) do
      # TECH-2818
      # Shipping emails had default_image every time when user bought the default product (750ml size for example).
      # Tried to replicate FE functionality, if no image in product then fallback to product grouping's image.
      has_images? ? images.first.photo.url(image_size) : product_size_grouping.featured_image(image_size)
    end
  end

  def image_urls(image_size = :small)
    Rails.cache.fetch("product:#{id}:#{updated_at}:image_urls:#{image_size}", expires_in: 4.hours) do
      has_images? ? images.map { |i| i.photo.url(image_size) } : product_size_grouping.image_urls(image_size)
    end
  end

  def default_image_url(image_size)
    "#{ENV['ASSET_HOST']}/images/defaults/#{hierarchy_category_name.to_s.parameterize}_#{hierarchy_type_name.to_s.parameterize}_#{image_size}.jpg"
  end

  def cached_properties
    Rails.cache.fetch("Product-ProductProperties-#{id}-#{updated_at}", expires_in: 4.hours) do
      product_properties.map { |pp| { name: pp.property.display_name, value: pp.description } }
    end
  end

  # Price of cheapest variant
  def price
    active_variants.exists? ? price_range.first : raise(VariantRequiredError)
  end

  # Duplicated in product grouping
  def extended_description
    if hierarchy_category&.id == 1
      [description, product_type&.description].compact.join("\r\n\r\n")
    else
      description
    end
  end

  # PROPERTY LOGIC
  def get_property(property_name)
    property = Property.find_by(identifing_name: property_name)
    return nil if property.nil? # nil, do nothing if that property DNE

    product_property = product_properties.find_by(property: property)
    product_property ? product_property.description : nil
  end

  def update_property(property_name, new_value)
    property = Property.find_by(identifing_name: property_name)
    return nil if property.nil? || new_value.nil? # nil, do nothing if that property DNE

    product_property = product_properties.find_or_initialize_by(property: property)
    product_property.update_attribute(:description, new_value)
  end

  def get_cached_property(property_name)
    property = cached_product_property_by_value(property_name)
    property.nil? ? nil : property[:value]
  end

  def country
    get_cached_property('country')
  end

  def region
    get_cached_property('region')
  end

  def year
    get_cached_property('year')
  end

  def appellation
    get_cached_property('appellation')
  end

  def varietal
    get_cached_property('varietal')
  end

  def humanize_volume
    # 12 and 'oz' should == '12oz'
    # 750 and 'ML' should == '750ml'
    # 1 and 'L' should == '1L'
    # 1 and 'pint' should == '1 pint'
    # nils should return empty strings or 0
    unit = volume_unit.nil? ? '' : volume_unit.upcase
    unit = unit == 'L' ? unit : unit.downcase
    separator = unit == 'pint' ? ' ' : ''
    val = volume_value == volume_value.nil? ? 0.0 : volume_value
    val = val == val.to_i ? val.to_i : val
    [val.to_s, unit].join(separator)
  end

  def humanize_pack_size
    container_array[0].to_i > 1 ? "#{container_array[0]} pack" : ''
  end

  def container_array
    # nils should return empty strings or 1
    count = container_count.nil? ? 1 : container_count # default to 1 if nil
    ctype = count > 1 && !container_type.nil? ? container_type.downcase.pluralize : ''
    # return a list so we can work through the join in humanize_item_volume
    [count, ctype]
  end

  def humanize_item_volume
    # We need to iterate over this array and replace any empty string values with
    # nil, then we compact. This allows us to determine wether we need a comma
    # separator after count.
    volume_array = [humanize_volume, container_array[1]].reject { |i| i.to_s.empty? }

    count = humanize_pack_size
    count = "#{count}," unless volume_array.empty? || count.blank?

    [count, volume_array].flatten.join(' ').strip
  end

  def admin_item_volume
    count = container_count.nil? ? 1 : container_count # default to 1 if nil
    admin_container_type = container_type.nil? ? 'container' : container_type.downcase
    admin_container_type = admin_container_type.pluralize if count > 1
    volume_string = humanize_volume
    volume_string = "#{volume_string}," if volume_string.present?
    "#{volume_string} #{count} #{admin_container_type}".strip
  end

  def searchize_volume
    category = hierarchy_category&.name

    if %w[liquor wine].include?(category)
      humanize_volume.presence
    elsif category == 'beer'
      if String(container_type).casecmp('keg').zero?
        'keg'
      elsif container_count.to_i > 1
        "#{container_count} pack"
      elsif container_count.to_i == 1
        'single'
      end
    else
      humanize_item_volume.presence
    end
  end

  # range of the product prices in plain english
  def display_price_range(delim = ' to ')
    price_range.join(delim)
  end

  def price_range
    return ['N/A', 'N/A'] if active_variants.empty?

    prices = active_variants.joins(:supplier)
                            .where(suppliers: { active: true })
                            .where(product_active: true)
                            .pluck(:price)

    prices.minmax { |a, b| a <=> b }
  end

  def display_name
    if item_volume && hierarchy_category && hierarchy_category.name == 'wine'
      case volume_value.to_i
      when 187
        "#{name} (Mini Bottle)"
      when 375
        "#{name} (Half Bottle)"
      else
        name
      end
    else
      name
    end
  end

  def uuid
    SecureRandom.uuid[0..4]
  end

  def get_other_products_with_upc(upc)
    Product.where("id != #{id} and '{#{upc}}' <@ additional_upcs")
  end

  # paginated results from the admin products grid
  def self.admin_grid(params = {}, _active_state = nil)
    grid = Product.includes(:variants).where.not(state: 'merged')
    grid = grid.inactive_filter(params[:inactive]) if params[:inactive].present?
    grid = grid.name_filter(params[:name]) if params[:name].present?
    grid = grid.brand_id_filter(params[:brand_id]) if params[:brand_id].present?
    grid = grid.product_type_filter(params[:product_type_id]) if params[:product_type_id].present?
    grid
  end

  def self.inventory_grid(params)
    grid = Product.active.order("#{params[:sidx]} #{params[:sord]}")
                  .includes(variants: [:inventory])

    grid = grid.where('variants.supplier_id' => params[:supplier_id]) if params[:supplier_id].presence
    grid
  end

  def product_property_by_value(name)
    prop_table = Property.arel_table
    product_properties.joins(:property)
                      .find_by("#{prop_table.name}.identifing_name" => name)
  end

  def cached_product_property_by_value(name)
    cached_properties.select { |p| p[:name].casecmp(name.downcase).zero? }.pop
  end

  def to_selectize_json
    "{'id':'#{id}', 'name':'#{name}'}"
  end

  def simple_duplicate(options = {})
    new_product = Product.new(name: name, product_grouping_id: product_grouping_id)
    new_product.assign_attributes(options)
    new_product
  end

  def update_apis_accessed(api_name)
    all_apis = apis_accessed + [api_name]
    update(apis_accessed: all_apis.uniq)
  end

  INDEX_ATTRIBUTES_FROM_VARIANT = Set['supplier_id', 'deleted_at', 'product_id'].freeze
  INDEX_ATTRIBUTES_FROM_PRODUCT = Set['state', 'item_volume', 'name', 'searchable', 'product_grouping_id', 'default_search_hidden'].freeze
  INDEX_ATTRIBUTES_FROM_PRODUCT_SIZE_GROUPING = Set['brand_id', 'hierarchy_category_id', 'hierarchy_type_id', 'hierarchy_subtype_id', 'default_search_hidden'].freeze
  INDEX_ATTRIBUTES_KNOWN_PRODUCTS_FROM_PRODUCT = Set['deleted_at', 'state', 'item_volume', 'name', 'searchable', 'product_grouping_id', 'upc', 'additional_upcs', 'container_type'].freeze
  INDEX_ATTRIBUTES_KNOWN_PRODUCTS_FROM_VARIANT = Set['deleted_at', 'product_id', 'original_name', 'price'].freeze

  def self.should_reindex_from_variant?(record)
    record.destroyed? || record.previous_changes.any? { |attribute, _| INDEX_ATTRIBUTES_FROM_VARIANT.include?(attribute) }
  end

  def self.should_reindex_from_product?(record)
    record.destroyed? || record.previous_changes.any? { |attribute, _| INDEX_ATTRIBUTES_FROM_PRODUCT.include?(attribute) }
  end

  def self.should_reindex_from_product_size_grouping?(record)
    record.destroyed? || record.previous_changes.any? { |attribute, _| INDEX_ATTRIBUTES_FROM_PRODUCT_SIZE_GROUPING.include?(attribute) }
  end

  def self.should_reindex_known_products_from_product?(record)
    record.destroyed? || record.previous_changes.any? { |attribute, _| INDEX_ATTRIBUTES_KNOWN_PRODUCTS_FROM_PRODUCT.include?(attribute) }
  end

  def self.should_reindex_known_products_from_variant?(record)
    record.destroyed? || record.previous_changes.any? { |attribute, _| INDEX_ATTRIBUTES_KNOWN_PRODUCTS_FROM_VARIANT.include?(attribute) }
  end

  def reindex_async(has_changed = false)
    MetricsClient::Metric.emit("reindex.products.has_changed.#{has_changed}", 1)

    if has_changed
      # Some Product attributes changed, does it affect any index?
      ProductReindexWorker.perform_async(id)      if Product.should_reindex_from_product?(self)
      variants.find_each(&:reindex_async)         if Variant.should_reindex_from_product?(self)
      product_size_grouping&.reindex_async        if ProductSizeGrouping.should_reindex_from_product?(self)
      KnownProductReindexWorker.perform_async(id) if Product.should_reindex_known_products_from_product?(self)
    else
      # Caller decided Product needs reindexing
      ProductReindexWorker.perform_async(id)
    end
  end

  def permalink_with_grouping
    [product_size_grouping_permalink, permalink].compact.join('/')
  end

  def toggle_activation
    inactive? ? activate : deactivate
  end

  def create_grouping
    ProductSizeGrouping.group_product(self) unless product_grouping_id
  end

  def default_tax_code
    return nil if product_type.nil?

    product_type.get_tax_code
  end

  def display_name_with_id
    "#{display_name} (pid: #{id})"
  end

  def product_trait_image
    return if product_trait&.main_image_url.blank?

    # Salsify images comes with http schema
    uri = URI.parse(product_trait&.main_image_url)
    uri.scheme = 'https'
    uri.to_s
  end

  def product_trait_name
    product_trait&.title || product_size_grouping.name
  end

  private

  def not_active_on_create!
    self.deleted_at = Time.zone.now
  end

  def reset_apis_flag
    self.apis_accessed = [] if name_changed?
    true # otherwise this function evaluates to false and doesn't run
  end

  def should_generate_new_friendly_id?
    name_changed? || item_volume_was != (item_volume || '') || super
  end

  def permalink_candidates
    [
      %i[name item_volume],
      %i[name item_volume uuid],
      %i[name item_volume uuid],
      [:name, :item_volume, '-', :uuid]
    ]
  end

  def log_activation
    log = ActivationLog.new
    log.score = quality_score
    log.product_id = id
    log.log_attributes = attributes

    log.save
  end

  def ensure_search_volume
    self.search_volume = searchize_volume
  end

  def check_active_pre_sale
    return if state == :active

    errors.add(:state, 'Product is currently assigned to an active pre sale') if PreSale.active.find_by(product_id: id).present?
  end

  def activate_inactive_variants
    Variant.where(product_id: id).self_inactive.update_all(deleted_at: nil)
  end
end
