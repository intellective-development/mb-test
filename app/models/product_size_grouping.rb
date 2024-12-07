# == Schema Information
#
# Table name: product_groupings
#
#  id                    :integer          not null, primary key
#  featured              :boolean          default(FALSE), not null
#  searchable            :boolean          default(TRUE), not null
#  state                 :string(255)      default("active")
#  brand_id              :integer
#  product_content_id    :integer
#  hierarchy_category_id :integer
#  hierarchy_subtype_id  :integer
#  hierarchy_type_id     :integer
#  product_type_id       :integer
#  meta_description      :string(255)
#  meta_keywords         :string(255)
#  name                  :string(255)      not null
#  permalink             :string(255)
#  description           :text
#  keywords              :text
#  created_at            :datetime
#  updated_at            :datetime
#  tax_category_id       :integer
#  trimmed_name          :string
#  gift_card_theme_id    :integer
#  default_search_hidden :boolean          default(FALSE)
#  business_remitted     :boolean          default(FALSE)
#  master                :boolean          default(FALSE)
#  liquid_id             :string
#
# Indexes
#
#  index_product_groupings_on_brand_id               (brand_id)
#  index_product_groupings_on_gift_card_theme_id     (gift_card_theme_id)
#  index_product_groupings_on_hierarchy_category_id  (hierarchy_category_id)
#  index_product_groupings_on_hierarchy_subtype_id   (hierarchy_subtype_id)
#  index_product_groupings_on_hierarchy_type_id      (hierarchy_type_id)
#  index_product_groupings_on_liquid_id              (liquid_id) UNIQUE
#  index_product_groupings_on_name                   (name)
#  index_product_groupings_on_permalink              (permalink) UNIQUE
#  index_product_groupings_on_product_content_id     (product_content_id)
#  index_product_groupings_on_product_type_id        (product_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (gift_card_theme_id => gift_card_themes.id)
#
class ProductSizeGrouping < ActiveRecord::Base
  extend FriendlyId
  include CreateUuid

  WHITELIST_PROPERTIES = %w[alcohol region country organic kosher appellation varietal screwcap style gluten_free year ibu].freeze

  self.table_name = 'product_groupings'

  acts_as_taggable_on :tags

  serialize :keywords, Array

  auto_strip_attributes :name, :description, :meta_description, :meta_keywords

  friendly_id :permalink_candidates, use: %i[slugged finders history], slug_column: :permalink
  # This is required due to the following issues in friendly_id 5.2.0
  # https://github.com/norman/friendly_id/issues/765
  alias_attribute :slug, :permalink

  belongs_to :brand
  belongs_to :hierarchy_category, class_name: 'ProductType'
  belongs_to :hierarchy_subtype,  class_name: 'ProductType'
  belongs_to :hierarchy_type,     class_name: 'ProductType'
  belongs_to :product_content
  belongs_to :product_type
  belongs_to :gift_card_theme

  has_one :product_grouping_search_data

  has_many :source_merges,      class_name: 'ProductMerge', foreign_key: :source_id
  has_many :destination_merges, class_name: 'ProductMerge', foreign_key: :destination_id

  has_many :images, -> { order(:position) }, as: :imageable, dependent: :destroy
  has_many :products, foreign_key: :product_grouping_id
  has_many :variants, through: :products
  has_many :paid_order_items, -> { joins(:shipment).merge(Shipment.paid) }, through: :variants, source: :paid_sibling_items
  has_many :paid_orders, -> { joins(:shipments).merge(Shipment.paid) }, through: :variants
  has_many :product_properties, as: :product, dependent: :destroy
  has_many :suppliers, through: :variants
  has_many :delivery_zones, through: :suppliers
  has_one :view, class_name: 'ProductGroupingStoreView', foreign_key: 'product_grouping_id'
  has_many :product_views, class_name: 'ProductGroupingExternalProductView', foreign_key: 'product_grouping_id'

  has_many :bundles, as: :source

  accepts_nested_attributes_for :images,             reject_if: proc { |t| (t['photo'].nil? && t['photo_from_link'].blank?) }, allow_destroy: true
  accepts_nested_attributes_for :product_properties, reject_if: proc { |attributes| attributes['description'].blank? }, allow_destroy: true

  before_create :update_trimmed_name
  before_save :update_trimmed_name,   if: :should_update_trimmed_name?
  before_save :update_type_hierarchy, if: :product_type_id_changed?

  after_commit -> { reindex_async(true) }

  delegate :name, to: :brand,               allow_nil: true, prefix: true
  delegate :name, to: :hierarchy_category,  allow_nil: true, prefix: true
  delegate :name, to: :hierarchy_subtype,   allow_nil: true, prefix: true
  delegate :name, to: :hierarchy_type,      allow_nil: true, prefix: true
  delegate :name, to: :product_type,        allow_nil: true, prefix: true

  #-----------------------------------------------------
  # StateMachine
  #-----------------------------------------------------
  state_machine initial: :active do
    state :active
    state :merged
    state :failed_merge

    before_transition to: :merge, do: [:check_completely_merged]
    after_transition  to: :active, do: [:activate_pending_products]

    event :activate do
      transition to: :active
    end
    event :merge do
      transition to: :merged, from: [:active]
    end
    event :fail_merge do
      transition to: :failed_merge, from: [:active]
    end
  end

  #-----------------------------------------------------
  # Scopes
  #-----------------------------------------------------
  scope :active, -> { where(state: :active) }
  scope :joins_valid_variants, -> { joins(:variants).merge(Variant.active.available) }
  # This has a limit of 50 items in order to optimize query performance.
  scope :purchased_with, lambda { |psg_id|
    select('product_groupings.*, count(product_groupings.id) AS product_groupings_count')
      .joins(products: { variants: { order_items: [:shipment] } })
      .where.not(id: psg_id)
      .where(state: 'active')
      .merge(Shipment.paid)
      .merge(Shipment.for_orders_with_psg(psg_id))
      .group('product_groupings.id')
      .order('product_groupings_count desc')
      .limit(50)
  }

  # TODO: This does not work if the permalink changes, we need to use FriendlyID
  scope :where_identifier, lambda { |identifiers|
    permalinks = Array(identifiers).select { |id| id.is_a?(String) }
    ids = Array(identifiers).select { |id| id.is_a?(Numeric) }
    permalinks += ProductSizeGrouping.where(id: ids).pluck(:permalink)
    ProductSizeGrouping.where(id: FriendlyId::Slug.where(sluggable_type: 'ProductSizeGrouping', slug: permalinks.uniq).pluck(:sluggable_id))
  }
  scope :catalog_filter, ->(product_states) { joins(:products).where(products: { state: product_states }) }
  scope :gift_card_type, -> { where(product_type: ProductType.find_by_name('gift card')) }

  #-----------------------------------------------------
  # SearchKick
  #-----------------------------------------------------
  # TODO: Consider moving the admin specific attributes out of this index, and
  #       into some view or other separate module etc.
  # TODO: We should probably move properties to this model rather than using .last,
  #       in most cases with exception of wine vintages we would expect them to be
  #       identical.
  # TODO: Consider moving properties to an array of key/values. It's cleaner though
  #       we should test performance since we'd be querying two things - if a
  #       property with a given key exists and then if the value exists.
  # TODO: Look at SearchKick 2.0's filterable fields if we wish to reduce index size.
  # TODO: Look at ElasticSearch's Routing Feature - Can this be used to speed up things?

  searchkick callbacks: false,
             index_name: -> { "#{name.tableize}_#{ENV['SEARCHKICK_SUFFIX'] || ENV['RAILS_ENV']}" },
             batch_size: 50,
             word_start: %i[name brand synthetic_name],
             suggest: [:name],
             merge_mappings: true,
             mappings: {
               properties: {
                 name_downcase: {
                   type: 'keyword'
                 },
                 variants: {
                   type: 'nested',
                   properties: {
                     variant_id: { type: 'integer' },
                     supplier_id: { type: 'integer' },
                     inventory: { type: 'integer' },
                     in_stock: { type: 'integer' },
                     active: { type: 'boolean' },
                     volume: { type: 'keyword' },
                     short_volume: { type: 'keyword' }, # TODO: do we need this?
                     short_pack_size: { type: 'keyword' }, # TODO: do we need this?
                     search_volume: { type: 'keyword' }, # TODO: do we need this?
                     container_type: { type: 'keyword' },
                     price: { type: 'float' },
                     sales_price: { type: 'float' },
                     permalink: { type: 'keyword' },
                     product_id: { type: 'keyword' },
                     upc: { type: 'keyword' },
                     thumb_url: { type: 'keyword' },
                     image_url_web: { type: 'keyword' },
                     image_url_mobile: { type: 'keyword' },
                     deals: Deal::ES_MAPPINGS
                   }
                 },
                 external_products: {
                   type: 'nested',
                   properties: {
                     product_id: { type: 'integer' },
                     permalink: { type: 'keyword' },
                     min_price: { type: 'float' },
                     max_price: { type: 'float' },
                     volume: { type: 'keyword' },
                     container_type: { type: 'keyword' },
                     short_pack_size: { type: 'keyword' },
                     short_volume: { type: 'keyword' },
                     thumb_url: { type: 'keyword' },
                     image_url_web: { type: 'keyword' },
                     image_url_mobile: { type: 'keyword' }
                   }
                 },
                 products: {
                   type: 'nested',
                   properties: {
                     has_active_pre_sale: { type: 'boolean' },
                     limited_time_offer: { type: 'boolean' }
                   }
                 },
                 deals: Deal::ES_MAPPINGS
               }
             }
  scope :search_import, lambda {
    includes [
      :brand,
      :products,
      :tags,
      :product_type,
      :hierarchy_category,
      :hierarchy_type,
      :hierarchy_subtype,
      :images,
      :product_grouping_search_data,
      :product_views,
      { variants: [
          :inventory,
          { product: [
              :hierarchy_category
            ],
            supplier: %i[
              supplier_type
              delivery_zones
            ] }
        ],
        product_properties: [
          :property
        ] }
    ]
  }

  def search_data
    active_variants = variants.active.available.select(:supplier_id, :sku, :id)
    active_sup_ids = active_variants.map(&:supplier_id)
    p_properties = product_properties.joins(:property).includes(:property).where('properties.active = true')
    has_images = images?
    # DO NOT USE additional queries (.where, .find_by, .pluck ...) or it will defeat the eager load
    {
      active: active?,
      state: state,
      name: product_trait_name,
      product_name: trimmed_name.nil? ? name : trimmed_name,
      name_downcase: String(product_trait_name).downcase,
      variant_count: active_variants.length,
      skus: active_variants.map(&:sku),
      merchant_skus: products.active.map(&:mechant_sku).compact.uniq,
      product_count: products.select { |product| %w[active pending].include? product.state }.length,
      ancestor_ids: ancestor_ids,
      decendant_ids: decendant_ids,
      variant_ids: active_variants.map(&:id),
      description: product_trait_description,
      permalink: permalink,
      supplier_ids: active_sup_ids,
      supplier_id: active_sup_ids.first,
      tags: tags.map(&:name),
      searchable: product_type&.searchable? && searchable?,
      search_hidden: search_hidden?,
      keywords: search_keywords,
      properties: get_all_properties_from_cache(p_properties),
      appellation: get_property_from_cache('appellation', p_properties),
      country: get_property_from_cache('country', p_properties),
      varietal: get_property_from_cache('varietal', p_properties),
      region: get_property_from_cache('region', p_properties),
      root_type: hierarchy_category_name,
      root_type_id: hierarchy_category&.id,
      featured: featured?,
      product_ids: products.map(&:id),
      container_counts: products.map(&:container_count).uniq,
      container_types: products.map(&:container_type).uniq,
      item_volumes: products.map { |product| "#{product.volume_value}#{product.volume_unit}" }.uniq,
      synthetic_name: searchkick_synthetic_name,
      taxonomy: taxonomy,
      gift_card: gift_card?,
      available_supplier_ids: active_sup_ids,
      product_grouping_id: id,
      hierarchy_category_permalink: hierarchy_category ? hierarchy_category.permalink : nil,
      hierarchy_category_name: hierarchy_category_name,
      hierarchy_category: hierarchy_category_id,
      hierarchy_type_permalink: hierarchy_type ? hierarchy_type.permalink : nil,
      hierarchy_type_name: hierarchy_type_name,
      hierarchy_type: hierarchy_type_id,
      hierarchy_subtype_permalink: hierarchy_subtype ? hierarchy_subtype.permalink : nil,
      hierarchy_subtype_name: hierarchy_subtype_name,
      hierarchy_subtype: hierarchy_subtype_id,
      product_content_id: product_content_id,
      business_remitted: business_remitted,
      has_image: has_images,
      thumb_url: index_image(:small, has_images),
      image_url_mobile: index_image(:ios_product, has_images),
      image_url_web: index_image(:product, has_images),
      has_active_pre_sale: PreSale.active.find_by(product_id: products.ids).present?,
      limited_time_offer: products.where(limited_time_offer: true).any?
    }.merge(search_popularity_data).merge(admin_search_data).merge(search_conversions).merge(brand_search_data)
  end
  INDEX_ATTRIBUTES_FROM_VARIANT = Set['deleted_at', 'case_eligible', 'two_for_one', 'supplier_id', 'sale_price', 'price', 'product_id'].freeze
  INDEX_ATTRIBUTES_FROM_PRODUCT = Set['deleted_at', 'state', 'volume_value', 'volume_unit', 'container_count', 'container_type', 'product_grouping_id'].freeze
  INDEX_ATTRIBUTES_FROM_PRODUCT_SIZE_GROUPING = Set['deleted_at', 'state', 'name', 'brand_id', 'description', 'permalink', 'hierarchy_category_id', 'hierarchy_type_id', 'hierarchy_subtype_id', 'product_type_id', 'product_content_id', 'default_search_hidden'].freeze

  def self.should_reindex_from_variant?(record)
    record.destroyed? || record.previous_changes.any? { |attribute, _| INDEX_ATTRIBUTES_FROM_VARIANT.include?(attribute) }
  end

  def self.should_reindex_from_product?(record)
    record.destroyed? || record.previous_changes.any? { |attribute, _| INDEX_ATTRIBUTES_FROM_PRODUCT.include?(attribute) }
  end

  def self.should_reindex_from_product_size_grouping?(record)
    record.destroyed? || record.previous_changes.any? { |attribute, _| INDEX_ATTRIBUTES_FROM_PRODUCT_SIZE_GROUPING.include?(attribute) }
  end

  def index_image(size, has_images = nil)
    if has_images.nil?
      !images? && image_from_first_product_view(size) || view.image_url(size)
    else
      !has_images && image_from_first_product_view(size) || view.image_url(size)
    end
  end

  def image_from_first_product_view(size)
    product_views.find(&:image_id).try(:image_url, size)
  end

  def reindex_async(has_changed = false)
    MetricsClient::Metric.emit("reindex.product_groupings.has_changed.#{has_changed}", 1)

    if has_changed
      # Some ProductSizeGrouping attributes changed, does it affect any index?
      ProductSizeGroupingReindexWorker.perform_async(id) if ProductSizeGrouping.should_reindex_from_product_size_grouping?(self)
      variants.active.find_each(&:reindex_async)         if Variant.should_reindex_from_product_size_grouping?(self)
      products.find_each(&:reindex_async)                if Product.should_reindex_from_product_size_grouping?(self)
    else
      # Caller decided ProductSizeGrouping needs reindexing
      ProductSizeGroupingReindexWorker.perform_async(id)
    end
  end

  def availabe_zones
    polygons = delivery_zones.map { |zone| zone[:json] } if delivery_zones.present?
    polygons.presence
  end

  def shipping_states
    zones = delivery_zones.select { |x| x.shipping_method&.shipped? }
    states = zones.map { |zone| zone[:value] } if zones.present?
    states.presence
  end

  def on_demand_zones
    zones = delivery_zones.select { |x| x.shipping_method&.on_demand? }
    polygon = zones.map { |zone| zone[:json] }
    polygon.presence
  end

  def pickup_zones
    zones = delivery_zones.select { |x| x.shipping_method&.pickup? }
    polygon = zones.map { |zone| zone[:json] }
    polygon.presence
  end

  def active_supplier_ids
    variants.active.available.map(&:supplier_id).uniq
  end

  def search_conversions
    {
      conversions: Rails.cache.read("search_conversions:#{self.class.name}:#{id}") || {}
    }
  end

  def search_keywords
    Array(product_type && product_type.keywords).unshift(*keywords)
  end

  def search_popularity_data
    # Commenting it because we are going to do reindex using the read only database
    # create_product_grouping_search_data unless product_grouping_search_data

    {
      orderer_ids_60day: product_grouping_search_data&.orderer_ids_60day || [],
      times_ordered: product_grouping_search_data&.times_ordered || 0,
      popularity: product_grouping_search_data&.popularity || 0,
      popularity_60day: product_grouping_search_data&.popularity_60day || 0,
      frequently_ordered_with: product_grouping_search_data&.frequently_ordered_with || []
    }
  end

  def brand_search_data
    {
      brand: brand_name == 'Unknown Brand' ? '' : brand_name,
      brand_permalink: brand&.permalink,
      brand_id: brand_id,
      sponsored_brand: brand&.sponsored,
      parent_brand_id: brand&.parent_brand_id
    }
  end

  def admin_search_data
    {
      product_states: products.map(&:state).uniq
    }
  end

  def should_index?
    state != 'merged' &&
      products.pluck(:state).uniq != ['merged'] &&
      variants.self_active.count.positive?
  end

  def search_hidden?
    default_search_hidden?
  end

  def gift_card?
    product_type&.name == 'gift card'
  end

  def ancestor_ids
    Rails.cache.fetch("product_size_grouping:#{id}:#{updated_at}:ancestor_ids", expires_in: 5.days) do
      product_type&.self_and_ancestors_ids
    end
  end

  def decendant_ids
    Rails.cache.fetch("product_size_grouping:#{id}:#{updated_at}:decendant_ids", expires_in: 5.days) do
      product_type&.self_and_descendant_ids
    end
  end

  def searchkick_synthetic_name
    ([name] + taxonomy).join(' ')
  end

  def last_product_trait
    @last_product_trait ||= ProductTrait.joins(:product).where(products: { product_grouping_id: id }).last
  end

  def product_trait_name
    last_product_trait&.title || name
  end

  def product_trait_description
    last_product_trait&.traits&.dig('Product_Description') || description
  end

  #-----------------------------------------------------
  # Class methods
  #
  # * These are primarily helper methods to ease the
  #   creation of and transition to ProductGroupings.
  #-----------------------------------------------------
  def self.group_products
    Product.where(product_size_grouping: nil).find_each do |product|
      ProductSizeGrouping.group_product(product)
    end
  end

  def self.set_grouping_image
    ProductSizeGrouping.find_each(&:set_product_image)
  end

  def self.create_from_product(product)
    ProductSizeGrouping.transaction do
      product.create_product_size_grouping(product.attributes.slice('name', 'featured', 'searchable'))
    end

    product.product_size_grouping
  end

  def self.build_from_product(product)
    grouping = ProductSizeGrouping.active.find_by(name: product.attributes['name'])
    grouping ||= ProductSizeGrouping.new
    grouping.name ||= product.name
    grouping.hierarchy_category ||= product.hierarchy_category
    grouping.product_type ||= product.product_type

    grouping
  end

  def self.get_views_from_es_result(result, supplier_ids)
    return [] if result['product_groupings'].empty?

    grouping_ids = result['product_groupings'].map { |pg| pg['id'] }
    variant_ids = result['product_groupings'].map { |pg| pg['variants'].map { |v| v['id'] } }.flatten

    ProductGroupingStoreView.retrieve_from_variants(grouping_ids, variant_ids, supplier_ids, 'volume').to_a
  end

  def self.group_product(product)
    grouping = ProductSizeGrouping.active.find_by(name: product.attributes['name'])
    grouping ||= ProductSizeGrouping.create_from_product(product)
    product.product_size_grouping = grouping
    product.save(validate: false)
    grouping.save(validate: false)

    ProductSizeGrouping.transfer_properties(grouping, product)
  end

  def self.regroup_product(product)
    new_grouping = product.product_size_grouping.dup
    new_grouping.permalink = nil # get around the permalink uniqueness validation
    new_grouping.save
    product.update(product_grouping_id: new_grouping.id)
  end

  def self.transfer_properties(grouping, product)
    properties_to_transfer = Property.where(identifing_name: WHITELIST_PROPERTIES)

    product.product_properties.where(property: properties_to_transfer).find_each do |product_property|
      existing_product_property = grouping.product_properties.find_by(property: product_property.property)
      grouping.product_properties.create(property: product_property.property, description: product_property.description) unless existing_product_property || product_property.description.blank?
    end
  end

  def self.already_exists?(name)
    ProductSizeGrouping.exists?(name: name)
  end

  def self.supplied_by(grouping_ids)
    groupings = ProductSizeGrouping.where_identifier(grouping_ids).active
    groupings.joins_valid_variants.pluck('variants.supplier_id').uniq
  end

  def self.find_by_identifier(identifier)
    ProductSizeGrouping.where_identifier(Array(identifier)).first
  end

  #-----------------------------------------------------
  # Instance methods
  #-----------------------------------------------------
  def get_property(name)
    property = Property.find_by(identifing_name: name)
    return nil if property.nil?

    product_property = product_properties.find_by(property: property)
    product_property ? product_property.description : nil
  end

  def featured?
    tags.map(&:name).include?('category_feature')
  end

  def set_property(name, value)
    property = Property.find_by(identifing_name: name)
    return nil if property.nil? || ProductProperty::DESCRIPTION_BLACKLIST.include?(String(value).downcase)

    product_property = product_properties.find_or_initialize_by(property: property)
    product_property.update(description: value)
  end

  def get_property_from_cache(name, p_properties = nil)
    if p_properties.nil?
      p_properties = product_properties
      ActiveRecord::Associations::Preloader.new.preload(p_properties, :property)
    end
    p_properties.select { |product_property| product_property&.property&.identifing_name == name }&.first&.description
  end

  def get_all_properties_from_cache(p_properties = nil)
    if p_properties.nil?
      p_properties = product_properties
      ActiveRecord::Associations::Preloader.new.preload(product_properties, :property)
      p_properties = p_properties.select { |product_property| product_property&.property&.active }
    end
    p_properties&.map do |product_property|
      parsed_property = {
        name: product_property&.property&.display_name,
        value: product_property&.description
      }
      parsed_property
    end
  end

  def product_page_url
    "#{ENV['WEB_STORE_URL']}/store/product/#{permalink}"
  end

  def image_url=(val = nil)
    val ? UpdateProductSizeGroupingImageJob.perform_later(self, val) : nil
  end

  def set_image(url)
    images.create(photo_from_link: url)
  rescue StandardError => e
    Rails.logger.error "Error setting image '#{url}' to Grouping #{id}: #{e}"
    raise
  end

  def set_product_image
    images.delete_all unless images.empty?

    candidates = products.order_by_volume.map { |product| product.featured_image(:original).include?('defaults') ? nil : product.featured_image(:original) }.compact.reverse

    while images.empty? && candidates.present?
      begin
        url = candidates.pop
        set_image(url)
      rescue StandardError => e
        Rails.logger.error "Error copying image '#{url}' to Grouping #{id}: #{e}"
      end
    end
  end

  def image_urls(image_size = :small)
    Rails.cache.fetch("product_size_grouping:#{id}:#{updated_at}:image_urls:#{image_size}", expires_in: 4.hours) do
      images.empty? ? [image_from_first_product_view(image_size) || default_image_url(image_size)] : images.map { |i| i.photo.url(image_size) }
    end
  end

  def default_image_url(image_size)
    # TODO: this is broken if the type level does not have a default image set. Going forward, we should likely move towards using ProductImageUrlService
    "#{ENV['AWS_BUCKET']}/assets/defaults/#{hierarchy_category_name.to_s.parameterize}_#{hierarchy_type_name.to_s.parameterize}_#{image_size}.jpg"
  end

  def featured_image(image_size = :small)
    Rails.cache.fetch("product_size_grouping::#{id}::featured_image::#{image_size}::#{updated_at}", expires_in: 24.hours) do
      images.empty? ? image_from_first_product_view(image_size) || default_image_url(image_size) : images.first.photo.url(image_size)
    end
  end

  def frequently_purchased_with(limit = 5)
    # storing only the ids to avoid errors serializing the entire model
    Rails.cache.fetch("product_size_grouping:#{id}:frequently_purchased_with:#{limit}", expires_in: 14.days) do
      ProductSizeGrouping.purchased_with(id).limit(limit).map(&:id)
    end
  end

  def get_entity(business, product = nil, supplier_ids = [])
    view_for_suppliers = ProductGroupingStoreView.retrieve_with_variants([id], supplier_ids).first
    if view_for_suppliers
      view_for_suppliers.entity(business: business, product: product)
    else
      view.entity(exclude_variants: true, business: business, product: product)
    end
  end

  def get_external_entity
    view_with_products = ProductGroupingStoreView.retrieve_with_products([id]).first
    if view_with_products
      view_with_products.entity(include_products: true, exclude_variants: true)
    else
      # we set include_products to ensure the EXTERNAL browse_type gets set, but because it's not
      # using the retrieve_with_products scope, "external_products" will be empty.
      view.entity(include_products: true, exclude_variants: true)
    end
  end

  def should_update_trimmed_name?
    trimmed_name.blank? || brand_id_changed? || name_changed?
  end

  def update_trimmed_name
    self.trimmed_name = ProductNameService.new(name, brand&.name).strip_brand
  end

  def update_type_hierarchy
    return true if product_type.nil?

    hierarchy = product_type.sorted_self_and_ancestors

    self.hierarchy_category = hierarchy[0]
    self.hierarchy_type     = hierarchy[1]
    self.hierarchy_subtype  = hierarchy[2]
  end

  def check_completely_merged
    fail_merge if products.count
  end

  def needs_categorization?
    product_type.nil? || product_type.unspecific?
  end

  def images?(force: false)
    return @has_images if defined?(@has_images) && !force

    @has_images = images.exists?
  end

  # in the admin form this is the method called when the form is submitted, The method sets
  # the keywords attribute to an array of these values
  def set_keywords=(value)
    self.keywords = value ? value.split(',').map(&:strip) : []
  end

  # method used by forms to set the array of keywords separated by a comma
  def set_keywords
    keywords ? keywords.join(', ') : ''
  end

  def extended_description
    if hierarchy_category_id == 1
      [description, product_type.description].compact.join("\r\n\r\n")
    else
      description
    end
  end

  def mergeable?
    active?
  end

  def activate_pending_products
    products.where(state: 'pending').activate!
  end

  def taxonomy
    [
      hierarchy_category_name,
      hierarchy_type_name,
      hierarchy_subtype_name
    ].compact
  end

  #-----------------------------------------------------
  # Permalink methods
  #-----------------------------------------------------
  def permalink_candidates
    [
      [:name],
      [:name, '-', :uuid]
    ]
  end

  def should_generate_new_friendly_id?
    (name_changed? && gift_card?) || super
  end

  def preload_product_types!
    relations = %i[hierarchy_category hierarchy_subtype hierarchy_type product_type]
    ids = relations.filter_map { |name| [name, public_send("#{name}_id")] }.to_h
    return if ids.blank?

    product_types = ProductType.where(id: ids.values.uniq).index_by(&:id)
    ids.each do |name, id|
      association(name)
        .tap { |association| association.target = product_types[id] }
        .tap { |association| association.set_inverse_instance(self) }
    end
  end
end
