# frozen_string_literal: true

# == Schema Information
#
# Table name: product_types
#
#  id                         :integer          not null, primary key
#  name                       :string(255)      not null
#  parent_id                  :integer
#  active                     :boolean          default(TRUE), not null
#  position                   :integer          default(0)
#  rgt                        :integer
#  lft                        :integer
#  searchable                 :boolean          default(TRUE), not null
#  description                :string(255)
#  product_image_file_name    :string(255)
#  product_image_content_type :string(255)
#  product_image_file_size    :integer
#  product_image_updated_at   :datetime
#  keywords                   :text
#  banner_image_file_name     :string(255)
#  banner_image_content_type  :string(255)
#  banner_image_file_size     :integer
#  banner_image_updated_at    :datetime
#  banner_featured_position   :integer
#  banner_image_fingerprint   :string(255)
#  permalink                  :string
#  tax_code                   :string(20)
#
# Indexes
#
#  index_product_types_on_name       (name)
#  index_product_types_on_parent_id  (parent_id)
#  index_product_types_on_permalink  (permalink) UNIQUE
#

class ProductType < ActiveRecord::Base
  extend FriendlyId
  include CreateUuid

  serialize :keywords, Array

  has_closure_tree order: 'position'

  auto_strip_attributes :name, squish: true

  has_many :product_size_groupings, dependent: :restrict_with_exception
  has_many :products, through: :product_size_groupings
  has_many :variants, through: :products
  has_many :suppliers, lambda {
    joins(:product_size_groupings).merge(ProductSizeGrouping.active).merge(Variant.active).joins('inner join inventories on inventories.id = variants.inventory_id').merge(Inventory.available).distinct
  }, through: :variants

  has_many :categorized_products, class_name: 'ProductSizeGrouping', foreign_key: :hierarchy_category_id
  has_many :typed_products, class_name: 'ProductSizeGrouping', foreign_key: :hierarchy_type_id
  has_many :subtyped_products, class_name: 'ProductSizeGrouping', foreign_key: :hierarchy_subtype_id
  has_many :paid_order_items, -> { joins(:shipment).merge(Shipment.paid) }, through: :variants, source: :order_items

  has_many :bundles, as: :source

  has_one :image, -> { order(:position) }, as: :imageable, dependent: :destroy
  has_one :ios_menu_image, class_name: 'Asset', as: :owner, dependent: :destroy
  has_one :product_type_search_data

  # TODO: this config should be shared with product_grouping/product
  has_attached_file :product_image, BASIC_PAPERCLIP_OPTIONS.merge(
    styles: { mini: ['48x48>', :jpg],
              small: ['240x400>', :jpg],
              product: ['360x400>', :jpg],
              category: ['640x290>', :jpg],
              thumb: ['200x240>', :jpg],
              detail: ['700x470>', :jpg],
              ios_product: ['x720>', :jpg] },
    processors: %i[trimmer padder],
    default_url: '/images/:style/missing.png',
    default_style: :small,
    keep_old_files: true,
    path: 'product_types/:id/:style.:extension'
  )

  has_attached_file :banner_image, BASIC_PAPERCLIP_OPTIONS.merge(
    styles: { default: ['235x215>', :jpg] },
    default_style: :default,
    path: 'product_types/:id/banner-:style-:fingerprint.:extension'
  )

  validates_attachment_content_type :product_image, content_type: %r{\Aimage/.*\Z}
  validates_attachment_content_type :banner_image, content_type: %r{\Aimage/.*\Z}
  validates :name, presence: true, length: { maximum: 255 }
  validates :position, presence: true

  accepts_nested_attributes_for :image,
                                reject_if: proc { |attributes| (attributes['photo'].nil? && attributes['photo_from_link'].blank?) },
                                allow_destroy: true

  accepts_nested_attributes_for :ios_menu_image, reject_if: proc { |attributes| attributes['file'].nil? }

  # To generate friendly id slug correctly, ancestry must be saved first
  after_save :regenerate_slug
  before_save :set_tax_code

  #-----------------------------------------------------
  # Constants
  #-----------------------------------------------------

  UNIDENTIFIED_TYPE = 'unknown'
  HIDDEN_TYPE = 'hidden'

  UNSPECIFIC_TYPES = %w[red white].freeze

  BLESSED_VARIETALS = ['semillon', 'muscat blanc', 'sauvignon blanc', 'port', 'sherry',
                       'nebbiolo', 'red blend', 'white blend', 'merlot', 'sangiovese', 'cabernet sauvignon', 'pinot noir', 'barolo', 'syrah', 'gamay', 'montepulciano', 'barbaresco', 'chianti', 'malbec', 'bordeaux', 'cabernet franc', 'rioja', 'zinfandel', 'barbera', 'shiraz', 'bordeaux blend', 'dolcetto', 'garnacha', 'tempranillo', 'grenache', 'sangiovese grosso', 'petite sirah', 'corvina', 'lambrusco', 'cinsault', 'grenache', 'champagne', 'prosecco', 'asti', 'cava', 'riesling', 'chablis', 'txakolina', 'chardonnay', 'pouilly-fuisse', 'gruner', 'sauvignon blanc', 'pinot grigio', 'sancerre', 'pouilly-fume', 'chenin blanc', 'pinot blanc', 'albarino', 'viognier', 'muscadet', 'soave', 'gewurztraminer', 'moscato', 'cortese', 'grenache blanc', 'gruner veltliner', 'vermentino', 'trebbiano', 'semillon'].freeze

  LEVEL_NAME_MAP = {
    category: 0,
    type: 1,
    subtype: 2
  }.freeze

  #-----------------------------------------------------
  # Friendly ID methods
  #-----------------------------------------------------

  friendly_id :permalink_candidates, use: %i[slugged finders], slug_column: :permalink

  # This is required due to the following issues in friendly_id 5.2.0
  # https://github.com/norman/friendly_id/issues/765
  alias_attribute :slug, :permalink

  def permalink_candidates
    [
      :ancestry_path,
      [:ancestry_path, UUID.generate]
    ]
  end

  def regenerate_slug
    # This is required to update ancestry_path for root entity
    reload
    # Prevents infinite loop, regenerate slug only if it's uuid (not properly generated)
    if UUID.validate(permalink)
      self.permalink = nil
      save
    end
  end
  #-----------------------------------------------------
  # SearchKick methods
  #-----------------------------------------------------
  searchkick callbacks: :async,
             index_name: -> { "#{name.tableize}_#{ENV['SEARCHKICK_SUFFIX'] || ENV['RAILS_ENV']}" },
             batch_size: 200,
             searchable: %i[name synthetic_name keywords],
             word_start: %i[name synthetic_name]

  scope :search_import, -> { includes %i[product_type_search_data parent image] }

  def search_data
    {
      active: active,
      ancestor_ids: self_and_ancestors_ids,
      banner_featured_position: banner_featured_position,
      descendant_ids: self_and_descendant_ids,
      description: description,
      has_banner_image: banner_image.present?,
      id: id,
      keywords: keywords,
      level: level,
      name: name,
      supplier_ids: get_supplier_ids,
      synthetic_name: searchkick_synthetic_name
    }.merge(search_popularity_data)
  end

  def get_supplier_ids
    Supplier.joins(variants: { product: :product_size_grouping })
            .joins('inner join inventories on inventories.id = variants.inventory_id')
            .merge(Variant.active)
            .merge(Inventory.available)
            .where(product_size_grouping: { state: :active, product_type_id: id })
            .distinct
            .pluck(:id)
  end

  def search_popularity_data
    create_product_type_search_data unless product_type_search_data

    {
      popularity: product_type_search_data.popularity,
      popularity_60day: product_type_search_data.popularity_60day
    }
  end

  def should_index?
    !is_blacklisted?
  end

  def searchkick_synthetic_name
    name_list.join(' ')
  end

  #-----------------------------------------------------
  # Scopes
  #-----------------------------------------------------
  scope :root, -> { where(parent_id: nil).order(:position) }
  scope :active, -> { where(active: true) }

  #-----------------------------------------------------
  # Class methods
  #-----------------------------------------------------
  def self.admin_grid(params = {})
    grid = ProductType
    grid = grid.where('product_types.name LIKE ?', "#{params[:name]}%") if params[:name].present?
    grid
  end

  def self.parse_product_type_id(value)
    return nil if value.blank?

    value = value.is_a?(Array) ? value[0] : value

    /[a-z]/.match?(value) ? (ProductType.find_by(permalink: value)&.id || 0) : value.to_i
  end

  def self.parse_product_type_ids(array)
    array.map do |val|
      if /[a-z]/.match?(val)
        ProductType.find_by(permalink: val)&.id || 0
      else
        val.blank? ? nil : val.to_i
      end
    end
  end

  #-----------------------------------------------------
  # Pseudo accessors
  #-----------------------------------------------------
  def parent_parent_id
    level >= 2 ? parent.parent.id : nil
  end

  def parent_parent_id=(pid)
    if parent
      parent.parent_id = pid
    else
      build_parent(parent_id: pid)
    end
  end

  # in the admin form this is the method called when the form is submitted, The method sets
  # the keywords attribute to an array of these values
  # Based on the methods in product.rb
  def set_keywords=(value)
    self.keywords = value ? value.split(',').map(&:strip) : []
  end

  # method used by forms to set the array of keywords separated by a comma
  def set_keywords
    keywords ? keywords.join(', ') : ''
  end

  #-----------------------------------------------------
  # Instance methods
  #-----------------------------------------------------
  # TODO: JM: These are for backward compatibility with stuff that hung off
  # awesome_nested_set methods. Replace it at source, this is wasteful.
  alias level depth
  alias descendent_ids self_and_descendant_ids

  def sorted_self_and_ancestors
    self_and_ancestors.reorder('product_type_hierarchies.generations DESC, position')
  end

  # TODO: support partial hierarchy (can't just reverse `ancestors - in_ancestors`)
  def is_type?(type_name, *ancestor_names)
    # check that name is the same, and that the type's ancestors are subset of the given names.
    in_ancestors = ProductType.where(name: ancestor_names)
    name == type_name && (ancestors - in_ancestors).empty?
  end

  def get_tax_code
    self_and_ancestors.each do |pt|
      return pt.tax_code if pt.tax_code.present?
    end

    nil
  end

  def unspecific?
    root? || root.name == UNIDENTIFIED_TYPE || UNSPECIFIC_TYPES.include?(name.downcase)
  end

  def is_alcohol?
    self_and_ancestors.any? { |an| %w[liquor beer wine].include?(an.name) }
  end

  def is_liquor?
    self_and_ancestors.any? { |an| an.name == 'liquor' }
  end

  def is_beer?
    self_and_ancestors.any? { |an| an.name == 'beer' }
  end

  def is_cider_beer?
    self_and_ancestors.any? { |an| an.name == 'cider' && an.is_beer? }
  end

  def is_flavored_beer?
    self_and_ancestors.any? { |an| an.name == 'flavored' && an.is_beer? }
  end

  def is_wine?
    self_and_ancestors.any? { |an| an.name == 'wine' }
  end

  def is_red_wine?
    self_and_ancestors.any? { |an| an.name == 'red' && an.is_wine? }
  end

  def is_white_wine?
    self_and_ancestors.any? { |an| an.name == 'white' && an.is_wine? }
  end

  def is_sparkling_wine?
    self_and_ancestors.any? { |an| an.name == 'sparkling' && an.is_wine? }
  end

  def is_fortified_wine?
    self_and_ancestors.any? { |an| an.name == 'fortified' && an.is_wine? }
  end

  def is_snack_or_more?
    self_and_ancestors.any? { |an| an.name == 'snacks & more' }
  end

  def is_snack?
    self_and_ancestors.any? { |an| an.name == 'snack' && an.is_snack_or_more? }
  end

  def is_candy?
    self_and_ancestors.any? { |an| an.name == 'candy' && an.is_snack_or_more? }
  end

  def is_ice?
    self_and_ancestors.any? { |an| an.name == 'ice' && an.is_snack_or_more? }
  end

  def is_accessory?
    self_and_ancestors.any? { |an| an.name == 'accessories & party supplies' && an.is_snack_or_more? }
  end

  def is_mixer?
    self_and_ancestors.any? { |an| an.name == 'mixer' }
  end

  def is_energy_drink?
    self_and_ancestors.any? { |an| an.name == 'energy' && an.is_mixer? }
  end

  def is_blacklisted?
    name == UNIDENTIFIED_TYPE || name == HIDDEN_TYPE || !active || (root? && image.nil?)
  end

  def is_gift_card?
    name == 'gift card'
  end

  def name_list
    self_and_ancestors.pluck(:name)
  end

  def deep_permalink
    self_and_ancestors.pluck(:permalink).reverse.join('/')
  end

  def category_and_type
    if parent_id.nil? # if category
      { category: self, type: nil }
    else
      category = root
      type = if parent != root # if its parent is not a root, this is a subtype
               parent
             else # otherwise, its parent is root, so this is the type
               self
             end
      { category: category, type: type }
    end
  end

  def top_ancestor
    ProductType.find_by_sql("WITH RECURSIVE r AS (
                              #{ProductType.where(id: id).to_sql}
                              UNION
                              #{ProductType.joins('JOIN r on product_types.id = r.parent_id').to_sql}
                            ) SELECT * FROM r WHERE parent_id IS NULL;").first
  end

  def all_ancestors
    ProductType.find_by_sql("WITH RECURSIVE r AS (
                              #{ProductType.where(id: id).to_sql}
                              UNION
                              #{ProductType.joins('JOIN r on product_types.id = r.parent_id').to_sql}
                            ) SELECT * FROM r")
  end

  def all_children
    ProductType.find_by_sql("WITH RECURSIVE r AS (
                              #{ProductType.where(id: id).to_sql}
                              UNION
                              #{ProductType.joins('JOIN r on product_types.parent_id = r.id').to_sql}
                            ) SELECT * FROM r;") || []
  end

  def parent_tree
    ProductType.find(parent_id)&.type_tree_ordered unless parent_id.nil?
  end

  def type_tree_ordered
    (all_children + (parent_tree || [])).uniq(&:id)
  end

  def set_tax_code
    self.tax_code = nil if tax_code.blank?
  end
end
