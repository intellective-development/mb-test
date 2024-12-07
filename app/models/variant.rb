# == Schema Information
#
# Table name: variants
#
#  id                   :integer          not null, primary key
#  product_id           :integer          not null
#  sku                  :string(255)      not null
#  name                 :string(255)
#  price                :decimal(8, 2)    default(0.0), not null
#  deleted_at           :datetime
#  supplier_id          :integer
#  created_at           :datetime
#  updated_at           :datetime
#  inventory_id         :integer
#  product_active       :boolean          default(FALSE), not null
#  original_name        :string(255)
#  original_item_volume :string(255)
#  protected            :boolean          default(FALSE), not null
#  sale_price           :decimal(8, 2)    default(0.0), not null
#  case_eligible        :boolean          default(FALSE), not null
#  ca_crv               :decimal(, )
#  two_for_one          :decimal(8, 2)
#  overridable          :boolean          default(FALSE)
#  options_type         :integer          default("no_options")
#  external_brand_key   :string
#  original_upc         :string
#  original_price       :decimal(8, 2)    default(0.0), not null
#  custom_promo         :json
#  tax_exempt           :boolean          default(FALSE)
#  frozen_inventory     :boolean          default(FALSE)
#  product_grouping_id  :integer
#  liquid               :boolean
#  liquid_id            :string
#
# Indexes
#
#  index_variants_on_inventory_id               (inventory_id)
#  index_variants_on_liquid_id                  (liquid_id) WHERE (liquid_id IS NOT NULL)
#  index_variants_on_options_type               (options_type)
#  index_variants_on_product_grouping_id        (product_grouping_id)
#  index_variants_on_product_id_and_deleted_at  (product_id,deleted_at)
#  index_variants_on_sku                        (sku)
#  index_variants_on_state_attributes           (deleted_at,product_active,protected,id)
#  index_variants_on_supplier_id                (supplier_id)
#  index_variants_on_supplier_id_and_liquid_id  (supplier_id,liquid_id) WHERE (deleted_at IS NULL)
#  variants_product_id_id_idx                   (product_id,id)
#  variants_sku_supplier_id_idx                 (sku,supplier_id)
#

# For Minibar, a variant is an instance of a specific product that is sold by a specific supplier.
#
#   =>  It will have a unique SKU
#   =>  It will have its own inventory
#   =>  It may have a different price
class Variant < ActiveRecord::Base
  include Variant::FacebookFeedSerializer
  include Wisper::Publisher

  auto_strip_attributes :name, :original_name, squish: true

  belongs_to :inventory
  belongs_to :product, inverse_of: :variants
  belongs_to :supplier, inverse_of: :variants

  has_one :product_size_grouping, through: :product
  has_one :brand, through: :product_size_grouping
  has_one :product_content, through: :product_size_grouping
  has_one :product_grouping_search_data, through: :product_size_grouping
  has_one :product_grouping_variant_store_view
  has_one :product_type, through: :product_size_grouping
  has_one :variant_store_view, class_name: 'ApiViews::VariantStoreView'

  has_many :order_items, inverse_of: :variant
  has_many :paid_orders, -> { merge(Shipment.paid) }, through: :order_items, source: :order
  has_many :paid_orderers, -> { merge(Shipment.paid).distinct }, through: :paid_orders, source: :user
  has_many :paid_sibling_items, -> { joins(:shipment).merge(Shipment.paid) }, through: :siblings, source: :order_items
  has_many :siblings, through: :product, source: :variants

  delegate :appellation,          to: :product, allow_nil: true
  delegate :container_type,       to: :product, allow_nil: true
  delegate :count_on_hand,             to: :inventory
  delegate :count_pending_to_customer, to: :inventory
  delegate :country,              to: :product, allow_nil: true
  delegate :description,          to: :product_size_grouping, allow_nil: true
  delegate :display_name,         to: :product, allow_nil: true, prefix: true
  delegate :extended_description, to: :product, allow_nil: true, prefix: true
  delegate :hierarchy_category,   to: :product_size_grouping, allow_nil: true
  delegate :hierarchy_subtype,    to: :product_size_grouping, allow_nil: true
  delegate :hierarchy_type,       to: :product_size_grouping, allow_nil: true
  delegate :item_volume,          to: :product, allow_nil: true
  delegate :low_stock?, to: :inventory
  delegate :name,                 to: :brand, allow_nil: true, prefix: true
  delegate :name,                 to: :product_size_grouping, allow_nil: true
  delegate :name,                 to: :product_size_grouping, allow_nil: true, prefix: :product # TODO: deprecate use of product_name in favor of psg delegate
  delegate :permalink,            to: :product, allow_nil: true
  delegate :quantity_available,        to: :inventory
  delegate :quantity_purchaseable,     to: :inventory
  delegate :region,               to: :product, allow_nil: true
  delegate :searchable,           to: :product, allow_nil: true
  delegate :sold_out?, to: :inventory
  delegate :upc, to: :product, allow_nil: true

  before_validation :fill_inventory, unless: :inventory

  before_save :set_product_active, :persists_product

  after_commit -> { reindex_async(true) if should_reindex? }

  validates :inventory,  presence: true
  validates :price,      numericality: { greater_than_or_equal_to: 0.01 }
  validates :product,    presence: true
  validates :sale_price, numericality: { greater_than_or_equal_to: 0, less_than: ->(variant) { variant.attributes['price'] } }
  validates :sku,        variant_sku: true, presence: true, length: { maximum: 255 }

  accepts_nested_attributes_for :inventory
  accepts_nested_attributes_for :supplier

  attr_accessor :_create, :_destroy, :skip_reindex

  scope :active,                -> { where(deleted_at: nil, product_active: true) }
  scope :available,             -> { joins(:inventory).merge(Inventory.available) }
  scope :in_product_groupings,  ->(product_grouping_ids) { joins(:product).where(products: { product_grouping_id: product_grouping_ids }) }
  scope :inactive,              -> { where(deleted_at: nil, product_active: false) }
  scope :product_pending,       -> { joins(:product).where(products: { state: 'pending' }) }
  scope :purchasable_from,      ->(supplier_ids) { active.available.where(supplier_id: supplier_ids) }
  scope :self_active,           -> { where(deleted_at: nil) }
  scope :self_inactive,         -> { where.not(deleted_at: nil) }
  scope :non_gift_cards,        -> { where.not(options_type: options_types[:gift_card]) }
  scope :engraving,             -> { joins(:supplier).where(suppliers: { engraving: true }) }
  scope :supplier_variants_by_names, ->(supplier_id, names) { where('lower(name) ~~ ANY(?)', "{#{names}}").where(supplier_id: supplier_id) }
  scope :unavailable, -> { joins(:inventory).merge(Inventory.unavaliable) }

  ES_CUSTOM_PROMO_MAPPINGS = {
    properties: {
      type: { type: 'keyword' },
      amount: { type: 'keyword' }
    }
  }.freeze

  #-----------------------------------------------------
  # SearchKick methods
  #-----------------------------------------------------
  searchkick callbacks: false,
             index_name: -> { "#{name.tableize}_#{ENV['SEARCHKICK_SUFFIX'] || ENV['RAILS_ENV']}" },
             batch_size: 50,
             word_start: %i[product_grouping_name brand],
             suggest: [:product_grouping_name],
             searchable: %i[appellation brand brand_permalink container_type country product_grouping_description hierarchy_category_name hierarchy_category_permalink hierarchy_subtype_name hierarchy_subtype_permalink hierarchy_type_name hierarchy_type_permalink keywords product_grouping_name product_grouping_image_url_mobile product_grouping_image_url_web product_grouping_permalink product_grouping_thumb_url product_name region root_type dtc_states taxonomy],
             merge_mappings: true,
             mappings: {
               properties: {
                 name_downcase: { type: 'keyword' },
                 name: { type: 'keyword' },
                 product_grouping_properties: {
                   type: 'nested',
                   properties: {
                     name: {
                       type: 'keyword',
                       fields: {
                         analyzed: {
                           type: 'text',
                           analyzer: 'searchkick_index'
                         }
                       }
                     },
                     value: {
                       type: 'keyword',
                       fields: {
                         analyzed: {
                           type: 'text',
                           analyzer: 'searchkick_index'
                         }
                       }
                     }
                   }
                 },
                 custom_promo: ES_CUSTOM_PROMO_MAPPINGS,
                 deals: Deal::ES_MAPPINGS
               }
             }

  scope :search_import, lambda {
    includes [
      :inventory,
      { product: [
          :properties,
          :hierarchy_category,
          :hierarchy_type,
          :hierarchy_subtype,
          :images,
          { product_size_grouping: [
            :product_grouping_search_data,
            :product_type,
            :brand,
            :hierarchy_category,
            :hierarchy_type,
            :hierarchy_subtype,
            :images,
            :view,
            :product_views,
            { product_properties: [
              :property
            ] }
          ] }
        ],
        supplier: %i[
          supplier_type
          delivery_zones
        ] }
    ]
  }

  enum options_type: { no_options: 0, gift_card: 1, engraving: 2 }

  def should_reindex?
    !skip_reindex
  end

  def should_index?
    deleted_at.nil? && !product_size_grouping.nil?
  end

  def search_hidden?
    product_size_grouping&.search_hidden? || product.search_hidden?
  end

  def search_routing
    supplier_id
  end

  def preload_search_data!
    product_size_grouping = product&.product_size_grouping
    product_size_grouping.preload_product_types!
    association(:product_size_grouping)
      .tap { |association| association.target = product_size_grouping }
      .tap { |association| association.set_inverse_instance(self) }
    product
      .association(:hierarchy_category)
      .tap { |association| association.target = product_size_grouping&.hierarchy_category }
      .tap { |association| association.set_inverse_instance(product) }
    product_size_grouping
      .view.association(:product_type)
      .tap { |association| association.target = product_size_grouping&.product_type }
      .tap { |association| association.set_inverse_instance(product_size_grouping.view) }
  end

  def search_data
    product_size_grouping = product&.product_size_grouping
    brand = product_size_grouping&.brand
    preload_search_data!
    {
      variant_id: id,
      permalink: permalink,
      name: product&.name,
      name_downcase: String(product&.name).downcase,
      product_name: product_size_grouping&.trimmed_name.nil? ? product_trait_name : product_size_grouping&.trimmed_name,
      country: product_size_grouping&.get_property_from_cache('country'),
      appellation: product_size_grouping&.get_property_from_cache('appellation'),
      region: product&.region,
      active: active?,
      in_stock: !sold_out?,
      inventory: items_in_stock,
      product_id: product&.id,
      supplier_id: supplier&.id,
      supplier_name: supplier&.display_name,
      sku: sku,

      # brand
      brand: brand&.name == 'Unknown Brand' ? '' : brand&.name,
      brand_permalink: brand&.permalink,
      brand_id: brand&.id,
      sponsored_brand: brand&.sponsored,
      parent_brand_id: brand&.parent_brand_id,

      # images
      thumb_url: product&.product_trait_image || product&.featured_image(:small),
      image_url_web: product&.product_trait_image || product&.featured_image(:product),
      image_url_mobile: product&.product_trait_image || product&.featured_image(:ios_product),

      # price
      original_price: original_price.to_f,
      price: price,

      # volume
      container_type: product&.container_type,
      volume: indexed_volume,
      short_volume: product&.short_volume,
      search_volume: product&.searchize_volume,
      short_pack_size: product&.short_pack_size,

      featured: should_feature_variant?,
      on_sale: on_sale?,
      two_for_one: two_for_one,
      case_eligible: case_eligible,
      has_engraving: supplier&.engraving?,
      dtc_states: supplier&.supplier_type&.dtc? ? supplier.delivery_zones.select { |zone| zone.type == 'DeliveryZoneState' }.map(&:value)&.uniq : [],

      searchable: searchable && product_size_grouping&.product_type&.searchable?,
      search_hidden: search_hidden? ? true : nil, # the returns need to be true/null to be possible to use the 'exists' clauses on ES template
      hierarchy: product&.cached_hierarchy,
      root_type: product_size_grouping&.hierarchy_category&.name,
      root_type_id: product_size_grouping&.hierarchy_category&.id,
      keywords: product_size_grouping&.search_keywords,

      tags: Array(product_size_grouping&.tag_list),

      # added upc
      upc: product&.upc,
      deals: presentable_deals.map(&:deals_data),
      custom_promo: custom_promo,

      product_content_id: product_size_grouping&.product_content_id
    }.merge!(search_hierarchy).merge!(search_popularity_data).merge!(search_product_grouping_data)
  end

  def search_hierarchy
    product_size_grouping = product&.product_size_grouping
    {
      hierarchy_category_permalink: product_size_grouping&.hierarchy_category ? product_size_grouping&.hierarchy_category&.permalink : nil,
      hierarchy_category_name: product_size_grouping&.hierarchy_category_name,
      hierarchy_category: product_size_grouping&.hierarchy_category_id,
      hierarchy_type_permalink: product_size_grouping&.hierarchy_type ? product_size_grouping&.hierarchy_type&.permalink : nil,
      hierarchy_type_name: product_size_grouping&.hierarchy_type_name,
      hierarchy_type: product_size_grouping&.hierarchy_type_id,
      hierarchy_subtype_permalink: product_size_grouping&.hierarchy_subtype ? product_size_grouping&.hierarchy_subtype&.permalink : nil,
      hierarchy_subtype_name: product_size_grouping&.hierarchy_subtype_name,
      hierarchy_subtype: product_size_grouping&.hierarchy_subtype_id,
      taxonomy: product_size_grouping&.taxonomy
    }
  end

  def search_product_grouping_data
    product_size_grouping = product&.product_size_grouping
    return {} if product_size_grouping.nil?

    {
      product_grouping_id: product_size_grouping.id,
      product_grouping_permalink: product_size_grouping.permalink,
      product_grouping_name: product_trait_name,
      product_grouping_name_downcase: String(product_trait_name).downcase,
      product_grouping_description: product_trait_description,
      product_grouping_properties: product_size_grouping.get_all_properties_from_cache,
      product_grouping_deals: product_size_grouping.view.presentable_deals(true, supplier).map(&:deals_data),
      product_grouping_has_image: product_size_grouping.images?,
      product_grouping_thumb_url: product_size_grouping.index_image(:small),
      product_grouping_image_url_mobile: product_size_grouping.index_image(:ios_product),
      product_grouping_image_url_web: product_size_grouping.index_image(:product),
      product_grouping_featured: product_size_grouping.featured?,
      gift_card: product_size_grouping.gift_card?,
      ancestor_ids: product_size_grouping&.ancestor_ids,
      decendant_ids: product_size_grouping&.decendant_ids
    }
  end

  def search_popularity_data
    product_size_grouping = product&.product_size_grouping
    {
      orderer_ids_60day: product_size_grouping&.product_grouping_search_data&.orderer_ids_60day,
      times_ordered: product_size_grouping&.product_grouping_search_data&.times_ordered,
      popularity: product_size_grouping&.product_grouping_search_data&.popularity,
      popularity_60day: product_size_grouping&.product_grouping_search_data&.popularity_60day,
      frequently_ordered_with: product_size_grouping&.product_grouping_search_data&.frequently_ordered_with
    }
  end

  def product_size_grouping_data
    {
      active: active?,
      in_stock: quantity_available,
      inventory: count_on_hand,
      on_sale: on_sale?,
      price: price.to_f,
      supplier_id: supplier_id,
      variant_id: id,
      volume: item_volume,
      # added permalink
      permalink: product&.permalink,
      # added product_id
      product_id: product_id,
      # added upc
      upc: product&.upc,
      sku: sku
    }
  end

  def deals_query_params
    Hash.new.tap do |hash| # rubocop:disable Style/EmptyLiteral
      hash[:suppliers] = Deal.for_types('Supplier').where("subject_id IN (#{supplier_id})") if supplier_id
    end
  end

  def deals
    @deals ||= Deals::QueryBuilder.new(deals_query_params).call
  end

  def deal_picker
    @picker = Deals::PresentableDealPicker.new(deals, is_alcohol: product_type&.is_alcohol?, state_abbreviation: supplier&.address&.state_abbr_name)
  end

  def presentable_deals
    @presentable_deals = []
    if case_eligible?
      volume_discounts = deal_picker.all_of_type(VolumeDiscount)
      @presentable_deals.concat(volume_discounts) unless volume_discounts.nil?
    end
    @presentable_deals.concat(add_two_for_one_to_deals) unless two_for_one.nil?
    @presentable_deals
  end

  def equal_amount?(deals, two_for_one_deal)
    deals.any? { |deal| deal.amount == two_for_one_deal.amount }
  end

  def add_two_for_one_to_deals
    deals = []
    deal_picker.all_of_type(TwoForOneDiscount).each do |two_for_one_deal|
      # two_for_one_deal.amount - two_for_one.to_f - check if the deal match for variant
      # equal_amount?(deals, two_for_one_deal) - check if exist two_for_one deals with duplicate amount
      deals << two_for_one_deal if !two_for_one_deal.nil? && two_for_one_deal.amount == two_for_one.to_f && !equal_amount?(deals, two_for_one_deal)
    end
    deals
  end

  # Added to handle the featuring of products now that the tag lives on the PSG
  def should_feature_variant?
    # avoid new query if product_size_grouping was already loaded
    product_size_grouping = product&.product_size_grouping
    if product_size_grouping&.tag_list&.include?('category_feature')
      # We only want to show 6 packs of beer or single 750ml bottles of wine/liquor
      product&.container_count == 6 || (product&.container_count == 1 && product&.volume_value == 750)
    else
      false
    end
  end

  INDEX_ATTRIBUTES_FROM_VARIANT = Set['deleted_at', 'supplier_id', 'sale_price', 'price', 'product_id'].freeze
  INDEX_ATTRIBUTES_FROM_PRODUCT = Set['deleted_at', 'cached_hierarchy', 'searchable', 'volume_value', 'volume_unit', 'container_count', 'container_type', 'product_grouping_id', 'default_search_hidden'].freeze
  INDEX_ATTRIBUTES_FROM_PRODUCT_SIZE_GROUPING = Set['deleted_at', 'brand_id', 'hierarchy_category_id', 'hierarchy_type_id', 'hierarchy_subtype_id', 'product_type_id', 'name', 'permalink', 'tag_list', 'description', 'trimmed_name', 'default_search_hidden'].freeze

  def self.should_reindex_from_variant?(record)
    record.destroyed? || record.previous_changes.any? { |attribute, _| INDEX_ATTRIBUTES_FROM_VARIANT.include?(attribute) }
  end

  def self.should_reindex_from_product?(record)
    record.destroyed? || record.images.any?(&:changed?) || record.previous_changes.any? { |attribute, _| INDEX_ATTRIBUTES_FROM_PRODUCT.include?(attribute) }
  end

  def self.should_reindex_from_product_size_grouping?(record)
    record.destroyed? || record.images.any?(&:changed?) || record.product_properties.any?(&:changed?) || record.previous_changes.any? { |attribute, _| INDEX_ATTRIBUTES_FROM_PRODUCT_SIZE_GROUPING.include?(attribute) }
  end

  # Allows us to ensure Product, ProductSizeGrouping and Variant indices are all updated
  def reindex_async(has_changed = false)
    MetricsClient::Metric.emit("reindex.variants.has_changed.#{has_changed}", 1)

    if has_changed
      # Some variant attributes changed, does it affect any index?
      VariantReindexWorker.perform_async(id)              if Variant.should_reindex_from_variant?(self)
      product&.reindex_async                              if Product.should_reindex_from_variant?(self)
      product_size_grouping&.reindex_async                if ProductSizeGrouping.should_reindex_from_variant?(self)
      KnownProductReindexWorker.perform_async(product.id) if product && Product.should_reindex_known_products_from_variant?(self)
    else
      # Caller decided variant needs reindexing
      VariantReindexWorker.perform_async(id)
    end
  end

  #-----------------------------------------------------
  # Class methods
  #-----------------------------------------------------
  def self.find_variant_for_suppliers(preferred_variant_id, supplier_ids)
    base_variant = Variant.unscoped.where(id: preferred_variant_id)
    return nil if base_variant.blank?

    # first, attempt to grab the preferred variant for the given suppliers
    purchasable_variant = base_variant.purchasable_from(supplier_ids).first

    # if that can't be found, check its siblings for a variant that matches the suppliers
    purchasable_variant || base_variant.first.siblings.purchasable_from(supplier_ids).first
  end

  def self.gift_card?(id)
    Variant.where(id: id, options_type: options_types[:gift_card]).exists?
  end

  def self.engraving?(id)
    Variant.where(id: id, options_type: options_types[:engraving]).exists?
  end

  #-----------------------------------------------------
  # Instance methods
  #-----------------------------------------------------
  def price
    on_sale? ? attributes['sale_price'] : attributes['price']
  end

  def id
    attributes['id']
  end

  def custom_promo
    attributes['custom_promo']
  end

  def original_price
    attributes['price']
  end

  def real_price
    attributes['price']
  end

  def discount_amount
    return 0.0 if sale_price.zero?

    (attributes['price'] - sale_price)
  end

  def on_sale?
    sale_price && !sale_price.zero?
  end

  def volume
    product.item_volume
  end

  def featured_image(image_size = :small)
    image_urls(image_size).first
  end

  def strip_brand_from_name
    ProductNameService.new(product_size_grouping.name, brand.name).strip_brand
  end

  def _remove=(arc)
    self.deleted_at = Time.zone.now if arc
  end

  # TODO: Should we fallback here to PSG image if product does not have one?
  def image_urls(image_size = :small)
    Rails.cache.fetch("variant:#{id}:#{updated_at}:image_urls:#{image_size}", expires_in: 24.hours) do
      product.image_urls(image_size)
    end
  end

  # returns whichever is smaller, the quantity or the count of purchasable items
  def quantity_cart_addable(qty, use_safe_qty_pad = true)
    inventory_purchaseable_quantity = quantity_purchaseable(use_safe_qty_pad)
    inventory_purchaseable_quantity < qty.to_i ? inventory_purchaseable_quantity : qty.to_i
  end

  def self_active?
    (deleted_at.nil? || deleted_at > Time.zone.now) && product.present?
  end

  # This is a form helper to inactivate a variant
  def inactivate=(val)
    self.deleted_at = Time.zone.now if !deleted_at && (val && (val == '1' || val.to_s == 'true'))
  end

  def inactivate
    deleted_at ? true : false
  end

  def inactivated?
    deleted_at.present?
  end

  # returns the product name with sku
  #  ex: obj.name_with_sku => Nike: 1234-12345-1234
  def name_with_sku
    [product_name, sku].compact.join(': ')
  end

  def name_with_volume
    "#{product_name} #{item_volume}"
  end

  # method used by forms to set the initial qty_to_add for variants
  def qty_to_add
    0
  end

  def two_for_one_visible?
    attributes['two_for_one'].nil? ? false : true
  end

  # paginated results from the admin Variant grid
  def self.admin_grid(product, params = {})
    grid = where(variants: { product_id: product.id }).includes(:product)
    grid = grid.where(products: { name: params[:product_name] }) if params[:product_name].present?
    grid = grid.where(['sku LIKE ? ', "#{params[:sku]}%"]) if params[:sku].present?
    grid
  end

  def self.inventory_grid(params)
    grid = active.order("#{params[:sidx]} #{params[:sord]}").includes(:inventory)
    grid = grid.where('supplier_id' => params[:supplier_id]) if params[:supplier_id].presence
  end

  def active?
    product&.active? && deleted_at.blank?
  end

  def inactive?
    !active?
  end

  def delivery_types
    supplier.shipping_methods.map(&:shipping_type)
  end

  def pretty_name
    "#{product_size_grouping&.name} (#{item_volume})"
  end

  def read_options(params)
    if params.present?
      if gift_card?
        GiftCardOptions.new(params)
      else # LCO-584, all non gift card items should be engravable
        EngravingOptions.new(params)
      end
    end
  end

  def supplier_admin_name
    (supplier&.name.presence || supplier&.permalink)
  end

  def supplier_name
    (supplier&.display_name.presence || supplier&.permalink)
  end

  def tax_exempt?
    attributes['tax_exempt'] == true
  end

  def soft_destroy
    update(deleted_at: Time.zone.now)
  end

  def product_trait_name
    product&.product_trait&.title || product_size_grouping&.name
  end

  def product_trait_description
    product&.product_trait&.traits&.dig('Product_Description') || product_size_grouping&.description
  end

  private

  def items_in_stock
    return count_on_hand if Feature[:skip_max_quantity_per_order_feature].enabled? || product.max_quantity_per_order.nil?

    [count_on_hand, product.max_quantity_per_order].min
  end

  def indexed_volume
    [product&.short_pack_size, product&.short_volume].filter(&:present?).join(', ')
  end

  def should_generate_new_friendly_id?
    (name_changed? && gift_card?) || super
  end

  def persists_product
    product.save! if product.id.nil?
    true
  end

  def set_product_active
    self.product_active = product&.active?
    true # callbacks must return true to run properly
  end

  def fill_inventory
    self.inventory = Inventory.create
  end
end
