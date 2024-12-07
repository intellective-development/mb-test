# frozen_string_literal: true

module RSA
  # ::RSA::MultiSelectService
  #
  # Service responsible to get a list of products from RSA
  class MultiSelectService < SelectService
    attr_reader :storefront_id, :product_grouping_ids, :product_ids, :bundle_ids, :supplier_ids, :address, :include_other_retailers

    # rubocop:disable Lint/MissingSuper
    def initialize(storefront_id, product_grouping_ids, product_ids, bundle_ids, supplier_ids, address, include_other_retailers: false)
      @storefront_id = storefront_id
      @product_grouping_ids = product_grouping_ids || []
      @product_ids = product_ids || []
      @bundle_ids = bundle_ids || []
      @supplier_ids = supplier_ids
      @address = address
      @include_other_retailers = include_other_retailers
    end
    # rubocop:enable Lint/MissingSuper

    def call
      build_multi_products
    end

    private

    def build_multi_products
      products = []
      body[:responses].each do |_key, value|
        products << build_products(value[:products] || value[:bundle][:products], value[:product_grouping_id])
      end
      products.flatten
    end

    def params
      { ids: product_grouping_ids + product_ids + bundle_ids }.merge(default_params)
    end

    def body
      @body ||= BarOSAPI::V1::Retailers.multi_select(params).with_indifferent_access
    end
  end
end
