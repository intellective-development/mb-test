require 'shared/validators/maximum_length'
require 'shared/validators/maximum_value'
require 'shared/validators/minimum_length'
require 'shared/validators/minimum_value'

module Shared::Helpers::BrowseParamHelpers
  extend Grape::API::Helpers

  params :shipping_state do
    optional :shipping_state, type: String, desc: 'Abbreviation of the shipping address state (e.g. NY)', allow_blank: true
  end

  params :pagination do
    optional :page, type: Integer
    optional :per_page, type: Integer
  end

  params :sorting do
    optional :sort_column, type: String
    optional :sort_direction, type: Symbol, values: %i[asc desc], default: :desc
  end

  params :search do
    optional :query, type: String, coerce_with: ->(val) { val.slice(0, 255) }
  end

  params :related_products do
    optional :count,                            type: Integer, desc: 'Count of items to return', default: 8
    optional :dynamic,                          type: Boolean, default: true
    optional :only_previous,                    type: Boolean, desc: 'Only show repeated content (for products, previously ordered)'
    optional :product_grouping_id,              type: String
    optional :product_grouping_similarity_type, type: String, default: 'content'
    optional :product_type_id,                  type: String
    optional :tags,                             type: Array
  end

  params :product_external do
    # Note - `brand` is passed as a string/integer and coerced into an Array containing itself and sub brands.
    requires :brand,    type: Array, desc: 'ID or permalink of brand', coerce_with: ->(val) { Brand.self_and_children(val) }
    optional :page,     type: Integer, desc: '', minimum_value: 1, default: 1
    optional :per_page, type: Integer, desc: '', maximum_value: 50, default: 15
  end

  params :product_searching do
    optional :base,               type: String
    # Note - `brand` is passed as a string/integer and coerced into an Array containing itself and sub brands.
    optional :brand,              type: Array, desc: 'ID or permalink of brand', coerce_with: ->(val) { Brand.self_and_children(val) }
    optional :category,           type: String,  desc: 'Name of Category'
    optional :country,            type: Array,   desc: 'The Country of Production'
    optional :exclude_previous,   type: Boolean, desc: 'Do not serve repeated content (for products, exclude previously ordered)'
    optional :facet_list,         type: Array,   desc: 'Whitelist of facets to return', default: []
    optional :hierarchy_category, type: Array,   desc: 'Category id or permalink', coerce_with: lambda { |val|
      val.is_a?(Array) ? ProductType.parse_product_type_ids(val) : [ProductType.parse_product_type_id(val)]
    }
    optional :hierarchy_subtype,  type: Array,   desc: 'Subtype ids',              coerce_with: ->(val) { ProductType.parse_product_type_ids(val) }
    optional :hierarchy_type,     type: Array,   desc: 'Type ids',                 coerce_with: ->(val) { ProductType.parse_product_type_ids(val) }
    optional :only_case_deals,    type: Boolean, desc: 'Only show case deal eligible products.'
    optional :only_two_for_one,   type: Boolean, desc: 'Only show Buy One Get One deal eligible products.'
    optional :only_previous,      type: Boolean, desc: 'Only show repeated content (for products, previously ordered)'
    optional :page,               type: Integer, desc: '', minimum_value: 1
    optional :per_page,           type: Integer, desc: '', maximum_value: 50
    optional :price,              type: Array,   desc: 'Price range', coerce_with: ->(vals) { vals.map { |val| val.split('-').map { |v| v == '*' ? '*' : v.to_f } } }
    optional :query,              type: String,  desc: 'Search query', default: '*', coerce_with: ->(val) { val.slice(0, 255) }
    optional :recommended,        type: Boolean, desc: 'Show personalized products for a given user'
    optional :region,             type: Array,   desc: 'The Region of Production'
    optional :search_volume,      type: String,  desc: 'The bottle/pack volume'
    optional :sort_direction,     type: String,  values: ['asc', 'desc', '']
    optional :sort,               type: String,  values: ['name', 'popularity_by_state', 'popularity', 'price', '']
    optional :tag,                type: String
    optional :type,               type: Integer, desc: 'Product Type ID', coerce_with: ->(val) { ProductType.parse_product_type_id(val) }
  end

  params :product_searching_v1 do
    optional :base,               type: String
    # Note - `brand` is passed as a string/integer and coerced into an Array containing itself and sub brands.
    optional :brand,              type: Array, desc: 'ID or permalink of brand', coerce_with: ->(val) { Brand.self_and_children(val) }
    optional :category,           type: String,  desc: 'Name of Category'
    optional :country,            type: Array,   desc: 'The Country of Production'
    optional :exclude_previous,   type: Boolean, desc: 'Do not serve repeated content (for products, exclude previously ordered)'
    optional :facet_list,         type: Array,   desc: 'Whitelist of facets to return', default: []
    optional :hierarchy_category, type: Integer, desc: 'Category id or permalink', coerce_with: ->(val) { ProductType.parse_product_type_id(val) }
    optional :hierarchy_subtype,  type: Array,   desc: 'Subtype ids',              coerce_with: ->(val) { ProductType.parse_product_type_ids(val) }
    optional :hierarchy_type,     type: Array,   desc: 'Type ids',                 coerce_with: ->(val) { ProductType.parse_product_type_ids(val) }
    optional :only_case_deals,    type: Boolean, desc: 'Only show case deal eligible products.'
    optional :only_two_for_one,   type: Boolean, desc: 'Only show Buy One Get One deal eligible products.'
    optional :only_previous,      type: Boolean, desc: 'Only show repeated content (for products, previously ordered)'
    optional :page,               type: Integer, desc: '', minimum_value: 1
    optional :per_page,           type: Integer, desc: '', maximum_value: 50
    optional :price,              type: Hash do
      requires :min, type: Integer, desc: 'The Minimum Price'
      requires :max, type: Integer, desc: 'The Maximum Price'
    end
    optional :query,              type: String,  desc: 'Search query', default: '*', coerce_with: ->(val) { val.slice(0, 255) }
    optional :recommended,        type: Boolean, desc: 'Show personalized products for a given user'
    optional :region,             type: Array,   desc: 'The Region of Production'
    optional :search_volume,      type: String,  desc: 'The bottle/pack volume'
    optional :sort_direction,     type: String,  values: ['asc', 'desc', '']
    optional :sort,               type: String,  values: ['name', 'popularity', 'price', '']
    optional :tag,                type: String
    optional :type,               type: Integer, desc: 'Product Type ID', coerce_with: ->(val) { ProductType.parse_product_type_id(val) }
    optional :product_ids,        type: Array,   desc: 'Product Id', coerce_with: ->(val) { Product.parse_product_ids(val) }
  end
end
