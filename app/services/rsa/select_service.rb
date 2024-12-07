# frozen_string_literal: true

module RSA
  # ::RSA::SelectService
  #
  # Service responsible to get a list of products from RSA
  class SelectService < BaseService
    TYPES = %i[non_engraving engraving].freeze
    SHIPPING_METHODS = %i[on_demand shipped].freeze

    attr_reader :storefront_id, :product_grouping_id, :product_id, :bundle_id, :address, :supplier_ids, :include_other_retailers

    # rubocop:disable Lint/MissingSuper
    def initialize(storefront_id, product_grouping_id, bundle_id, address, supplier_ids, product_id = nil, include_other_retailers: false)
      @storefront_id = storefront_id
      @product_grouping_id = product_grouping_id
      @product_id = product_id
      @bundle_id = bundle_id
      @address = address
      @supplier_ids = supplier_ids
      @include_other_retailers = include_other_retailers
    end
    # rubocop:enable Lint/MissingSuper

    def call
      build_products(response_rsa_products, body[:product_grouping_id])
    end

    private

    def build_products(rsa_products, rsa_product_grouping_id)
      products = []
      TYPES.product(SHIPPING_METHODS).each do |(type, shipping_method)|
        rsa_products[type][shipping_method].to_a.each do |product|
          products << build_product(type, shipping_method, product, rsa_product_grouping_id)

          next unless include_other_retailers

          product[:other_retailers]&.each do |other_product|
            products << build_product(type, shipping_method, other_product, rsa_product_grouping_id)
          end
        end
      end
      products
    end

    def host
      ENDPOINTS[ENV.fetch('ENV_NAME', 'development').to_sym] || ENDPOINTS[:staging]
    end

    def params
      { id: product_grouping_id.presence || product_id.presence || bundle_id }.merge(default_params)
    end

    def default_params
      {
        storefront_id: storefront_id.to_i,
        longitude: address.longitude,
        latitude: address.latitude,
        ship_state: address.state_name,
        **retailer_ids
      }
    end

    def body
      @body ||= BarOSAPI::V1::Retailers.select(params).with_indifferent_access
    end

    def response_rsa_products
      body[:products] || body[:bundle][:products]
    end

    def entities(key, id)
      body[:entities][key][id.to_s]
    end

    def retailer_ids
      supplier_ids.present? ? { retailer_ids: supplier_ids } : {}
    end

    def build_product(type, shipping_method, attrs, rsa_product_grouping_id)
      Structs::RSA::Product.new(
        type,
        shipping_method,
        attrs[:product][:id],
        attrs[:variant][:id],
        attrs[:variant][:price],
        attrs[:variant][:in_stock],
        attrs[:product][:short_volume],
        attrs[:is_presale],
        attrs[:presale],
        attrs[:customer_placement],
        bundle_id,
        rsa_product_grouping_id,
        build_supplier(attrs[:retailer])
      )
    end

    def build_supplier(attrs)
      delivery = attrs[:delivery] || entities(:shipping_methods, attrs[:shipping_method_id])
      Structs::RSA::Supplier.new(
        attrs[:id],
        attrs[:name],
        attrs[:supports_graphic_engraving],
        delivery[:delivery_minimum],
        delivery[:delivery_threshold],
        delivery[:delivery_fee],
        delivery[:delivery_expectation],
        delivery[:delivery_available],
        delivery[:next_delivery]
      )
    end
  end
end
