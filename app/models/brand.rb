# == Schema Information
#
# Table name: brands
#
#  id                        :integer          not null, primary key
#  name                      :string(255)
#  parent_brand_id           :integer
#  permalink                 :string(255)
#  created_at                :datetime
#  updated_at                :datetime
#  mobile_image_file_name    :string
#  mobile_image_content_type :string
#  mobile_image_file_size    :integer
#  mobile_image_updated_at   :datetime
#  description               :text
#  web_image_file_name       :string
#  web_image_content_type    :string
#  web_image_file_size       :integer
#  web_image_updated_at      :datetime
#  deleted_at                :datetime
#  state                     :string           default("active")
#  sponsored                 :boolean          default(FALSE)
#
# Indexes
#
#  index_brands_on_deleted_at       (deleted_at)
#  index_brands_on_name             (name)
#  index_brands_on_parent_brand_id  (parent_brand_id)
#  index_brands_on_permalink        (permalink) UNIQUE
#

class Brand < ActiveRecord::Base
  extend FriendlyId
  include PiedPiper

  acts_as_taggable
  acts_as_paranoid
  validates_as_paranoid

  has_descendents parent_key: 'parent_brand_id'

  auto_strip_attributes :name, squish: true

  friendly_id :permalink_candidates, use: %i[slugged finders history], slug_column: :permalink
  alias_attribute :slug, :permalink

  has_many :content_managers, through: :brand_content_managers, source: :user, inverse_of: :brand
  has_many :brand_content_managers, dependent: :destroy, inverse_of: :brand
  has_many :variants
  has_many :product_size_groupings, dependent: :nullify
  has_many :products, through: :product_size_groupings

  has_many :bundles, dependent: :destroy, as: :source

  has_many :brand_distributor_associations, dependent: :destroy
  has_many :distributors, through: :brand_distributor_associations

  # These represent relationships between brands, which is occasionally useful
  # for display or reporting purposes.
  #
  # For example ABI may own Budweiser, Goose Island and Coors etc.
  belongs_to :parent,   class_name: 'Brand', foreign_key: 'parent_brand_id'
  has_many :sub_brands, class_name: 'Brand', foreign_key: 'parent_brand_id'

  has_attached_file :mobile_image, BASIC_PAPERCLIP_OPTIONS.merge(path: 'brands/:id/:style/:basename.:extension')
  validates_attachment :mobile_image, content_type: { content_type: ['image/jpg', 'image/jpeg', 'image/png', 'image/gif'] }
  validates_attachment_size :mobile_image, less_than: 1.megabytes

  has_attached_file :web_image, BASIC_PAPERCLIP_OPTIONS.merge(path: 'brands/:id/:style/:basename.:extension')
  validates_attachment :web_image, content_type: { content_type: ['image/jpg', 'image/jpeg', 'image/png', 'image/gif'] }
  validates_attachment_size :web_image, less_than: 1.megabytes

  validates :parent_brand_id, :id, values_not_equal: true

  after_save :update_product_groupings

  #-----------------------------------
  # Scopes
  #-----------------------------------
  scope :unknown_first, -> { order(Arel.sql("#{table_name}.name = 'Unknown Brand' desc nulls last")) }
  scope :by_permalink,  ->(permalinks) { where(permalink: permalinks) }
  scope :matching_name, ->(name) { where('unaccent(lower(brands.name)) LIKE ?', "%#{name.downcase}%") }
  scope :not_parent_brand, -> { where.not('brands.id in (?)', Brand.distinct.pluck(:parent_brand_id).compact) }
  scope :merged,              -> { where(state: 'merged') }
  scope :not_merged,          -> { where.not(state: 'merged') }

  state_machine initial: 'active' do
    state 'active'
    state 'merged'

    event :merge do
      transition to: 'merged', from: ['active']
    end
  end

  #-----------------------------------------------------
  # SearchKick methods
  #-----------------------------------------------------
  searchkick callbacks: :async,
             index_name: -> { "#{name.tableize}_#{ENV['SEARCHKICK_SUFFIX'] || ENV['RAILS_ENV']}" },
             batch_size: 200,
             searchable: %i[name parent_name synthetic_name],
             word_start: %i[name parent_name synthetic_name],
             filterable: [],
             merge_mappings: true,
             mappings: {
               properties: {
                 has_active_in_stock_products: {
                   type: 'keyword'
                 },
                 state: {
                   type: 'text'
                 }
               }
             }

  def should_index?
    state != 'merged'
  end

  def search_data
    # Brand 'Unknown brand' has 700k associated product size groupings. Do not eager load here.
    # Also, filters on product size groupings / stocks are never used. We don't need them in brand index.
    {
      name: name,
      parent_name: parent&.name,
      has_children: descendents&.present?,
      has_parent: parent_brand_id.present?,
      has_groupings: true, # self_and_descendents_product_groupings&.present?,
      synthetic_name: searchkick_synthetic_name,
      has_active_in_stock_products: true, # products.any? { |p| p.variants.active.available.any? },
      state: state
    }
  end

  def searchkick_synthetic_name
    [name, product_grouping_taxonomy].join(' ')
  end

  #-----------------------------------
  # Class methods
  #-----------------------------------
  def self.admin_grid(params = {}, _active_state = nil)
    name_query = not_merged.name_filter(params[:name])
    name_query = name_query.where("brands.sponsored = #{params[:sponsored]}") if params[:sponsored].present?
    name_query
  end

  def self.name_filter(name)
    name.present? ? where('lower(brands.name) LIKE lower(?)', "#{name}%") : all
  end

  # Using a class method rather than a scope as we may want to lookup based on
  # permalink rather than numeric ID. If an invalid ID is provided then this
  # method will return an `ActiveRecord::RecordNotFound` error.
  #
  # This will trigger 2 fast DB queries, there is future potential to optimize
  # into a single query if we don't care about permalink history.
  def self.self_and_children(brand_ids)
    [brand_ids].flatten.flat_map do |brand_id|
      brand = Brand.find(brand_id)
      brand.sub_brands.pluck(:id).push(brand.id)
    end
  end

  #-----------------------------------
  # Instance methods
  #-----------------------------------
  def update_product_groupings
    if name_changed?
      product_size_groupings.find_each do |product_grouping|
        product_grouping.update_trimmed_name
        product_grouping.save!
      end
    elsif sponsored_changed?
      ProductGroupingAndVariantReindexByBrandWorker.perform_async(id)
    end
  end

  def self_and_descendents_product_groupings
    ProductSizeGrouping.distinct.where(brand_id: self_and_descendents.pluck(:id))
  end

  def active_self_and_descendents_product_groupings
    self_and_descendents_product_groupings.active
  end

  def parent?
    !sub_brands.empty?
  end

  def sub_brand?
    !parent.nil?
  end

  def self_and_sub_brand_ids
    [id].concat(sub_brands.pluck(:id))
  end

  def product_grouping_taxonomy
    # self_and_descendents_product_groupings.any? ? self_and_descendents_product_groupings[0].taxonomy.join(' ') : ''
    ProductSizeGrouping.find_by(brand_id: self_and_descendents.pluck(:id))&.taxonomy&.join(' ') || ''
  end

  private

  #-----------------------------------------------------
  # Permalink methods
  #-----------------------------------------------------
  def permalink_candidates
    [
      [:name],
      [:name, '-', UUID.generate]
    ]
  end
end
