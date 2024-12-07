module Shared::Helpers::ContentParamHelpers
  extend Grape::API::Helpers

  # Describes the device type. General convention here is:
  # "<platform>_<image asset size eg. 2x, 3x>_<screen width>x<screen height>"
  DEVICE_TYPES = %w[web web_1x web_2x].freeze

  params :content do
    requires :placement,  type: String, desc: 'String corresponding to specific placement location.', allow_blank: false
    optional :device,     type: String, desc: 'String corresponding to client device.', values: DEVICE_TYPES, allow_blank: false
    optional :context,    type: Hash, default: {} do
      optional :count,                            type: Integer, desc: 'Number of products to return. Only applies to specific queries.'
      optional :dynamic_identifier,               type: String,  desc: 'Returned with placement as part of id, distinguishes between instances of dynamic placements.'
      optional :exclude_previous,                 type: Boolean, desc: 'Do not serve repeated content (for products, exclude previously ordered)'
      optional :featured,                         type: Boolean, desc: 'Promote featured content'
      optional :only_previous,                    type: Boolean, desc: 'Only show repeated content (for products, previously ordered)'
      optional :page_type,                        type: String,  desc: 'The type of a page being shown. On a PLP, this might be reorder, category, search, etc.'
      optional :product_grouping_ids,             type: Array,   desc: 'Array of product_grouping_ids, used when looking for similar products.'
      optional :product_grouping_similarity_type, type: String,  values: %w[collaborative content], desc: 'type of filtering to do on products'
      optional :product_type_id,                  type: Integer, desc: 'Product Types, used when scoping.'
      optional :supplier_ids,                     type: Array,   default: [], desc: 'Array of supplier_ids for the current user.'
      optional :variant_id,                       type: Integer, desc: 'ID of variant. Used for either finding related products or excluding from query.'
      optional :browse_context,                   type: Hash,    desc: 'Describes browsing state (search, category, etc.). Same as params in product searching endpoint'
      optional :price, type: Hash, desc: 'Price data, used while filtering products.' do
        optional :min, type: Float, desc: 'Minimum Price'
        optional :max, type: Float, desc: 'Maximum Price'
      end
      optional :address, type: Hash, desc: 'Customers current address. Used when searching.' do
        requires :coords, type: Hash do
          requires :lat, type: Float, desc: 'Latitude'
          requires :lng, type: Float, desc: 'Longitude'
        end
      end
    end
    optional :count, type: Integer, desc: 'Integer indicating number of items to return. This may not apply for all placements.', default: 1
  end
end
