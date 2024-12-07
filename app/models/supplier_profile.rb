# == Schema Information
#
# Table name: supplier_profiles
#
#  id                  :integer          not null, primary key
#  categories          :hstore
#  supplier_id         :integer
#  created_at          :datetime
#  updated_at          :datetime
#  type_hierarchy      :text
#  delivery_mode       :integer          default("driving")
#  popular_searches    :string(255)      default([]), is an Array
#  apple_pay_supported :boolean          default(FALSE), not null
#  hierarchy_type_ids  :integer          default([]), is an Array
#
# Indexes
#
#  index_supplier_profiles_on_supplier_id  (supplier_id)
#

class SupplierProfile < ActiveRecord::Base
  CATEGORY_NAMES = %i[beer wine liquor mixers cider other].freeze
  DEFAULT_SEARCHES = ['pinot noir', 'champagne', 'sparkling wine', 'ice', 'prosecco', 'domestic beer', 'imported beer', 'rose', 'cider', 'gin', 'white wine', 'scotch', 'ipa', 'prosecco', 'chardonnay', 'vodka', 'bourbon', 'bartender', 'johnny walker', 'tequila', 'sauvignon blanc', 'napa valley', 'moscato', 'makers mark'].freeze

  store_accessor :categories
  serialize :type_hierarchy, JSON

  after_create :set_category_metadata
  after_create :set_type_metadata

  acts_as_taggable_on :tags
  belongs_to :supplier

  enum delivery_mode: {
    driving: 0,
    walking: 1,
    bicycling: 2
  }

  def set_category_metadata
    categories = ProductType.order(:position)
                            .roots
                            .active
                            .joins(:image)
                            .where("images.imageable_type = 'ProductType'")
                            .where('images.imageable_id = product_types.id')

    category_data = Hash.new(0)
    categories.each do |category|
      category_product_counts = Variant.joins(:product, :product_size_grouping).active.available.where(supplier_id: supplier_id)
                                       .where('product_groupings.product_type_id IN (?)', category.self_and_descendants.pluck(:id))
                                       .size
      store_name = CATEGORY_NAMES.include?(category.name.to_sym) ? category.name.to_sym : :other
      category_data[store_name] += category_product_counts
    end
    update(categories: category_data)
  end

  def set_type_metadata
    product_ids = supplier.variants.active.available.pluck(:product_id).uniq.compact
    product_type_ids = Product.joins(:product_size_grouping).where(id: product_ids).pluck(:hierarchy_category_id, :hierarchy_type_id, :hierarchy_subtype_id).flatten.uniq.compact
    valid_product_type_ids = ProductType.order(:position).where(id: product_type_ids).reject(&:is_blacklisted?).map(&:id)

    update_attribute(:hierarchy_type_ids, valid_product_type_ids)
  end

  # This method is used if we need to retrieve a list of all stocked product
  # type ids for a supplier, such as when we are making a personalization
  # related decision.
  # Speed is critical here so we use the type hierarchy rather than calculating
  # in real-time.
  def product_type_ids
    hierarchy_type_ids
  end

  private

  def filter_search_terms(array)
    # This will remove any substrings from the array, so ['vodk', 'vodka'] will
    # return ['vodka']
    array.reject { |s| array.any? { |i| i.starts_with?(s) && i != s } }
  end
end
