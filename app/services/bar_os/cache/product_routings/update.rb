# frozen_string_literal: true

module BarOS
  module Cache
    module ProductRoutings
      # BarOS::Cache::ProductRoutings::Update
      #
      # Class responsible to create the product routings cache for the BarOS app
      # This class needs the same logic of BarOS app
      # BarOS file: app/interactors/mini_bar/product_routings/update_cache.rb
      class Update < BaseService
        CACHE_KEY = 'MiniBar::ProductRoutings::Cache'

        attr_reader :storefront_id

        def initialize(storefront_id:)
          @storefront_id = storefront_id

          super
        end

        def call
          return if ENV['BAR_OS_REDIS_URL'].blank?

          (storefront_id ? Array.wrap(storefront_id) : [nil]).each do |id|
            cache_key = ActiveSupport::Cache.expand_cache_key(product_routing_cache_key(id, '*').compact)
            BarOS.cache.delete_matched(cache_key)
          end
          BarOS.cache.write_multi(cache_data) if cache_data.present?
        end

        protected

        def hash_keys(storefront_ids, states)
          Array.wrap(storefront_ids).product(Array.wrap(states).compact.map(&:upcase))
        end

        def product_routings
          (storefront_id ? ProductRouting.where(storefront_id: storefront_id) : ProductRouting)
            .where.not(product_id: nil)
        end

        def cache_data
          @cache_data ||=
            product_routings_by_key
            .select { |_key, values| values.present? }
            .transform_keys { |key| product_routing_cache_key(*key) }
        end

        def product_routings_by_key
          product_routings
            .each_with_object({}) do |product_routing, data|
            hash_keys(product_routing.storefront_id, product_routing.states_applicable).each do |key|
              data[key] ||= []
              data[key] << product_routing_hash(product_routing) if product_routing.active?
            end
          end
        end

        def product_routing_hash(product_routing)
          product_routing
            .slice(:product_id, :supplier_id, :engravable, :starts_at, :ends_at)
            .merge(quantity: product_routing.order_qty_limit - product_routing.current_order_qty)
        end

        # This method was extract from app/interactors/concerns/mini_bar/product_routings/cache.rb on BarOS app
        def product_routing_cache_key(storefront_id, ship_state)
          [CACHE_KEY, storefront_id, ship_state]
        end
      end
    end
  end
end
