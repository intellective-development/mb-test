# frozen_string_literal: true

module BarOS
  module Cache
    module PreSales
      # BarOS::Cache::PreSales::Update
      #
      # Class responsible to create the pre sales cache for the BarOS app
      # This class needs the same logic of BarOS app
      # BarOS file: app/interactors/concerns/mini_bar/pre_sales/cache.rb
      class Update < BaseService
        CACHE_KEY = 'MiniBar::PreSales::Cache'

        def call
          return if ENV['BAR_OS_REDIS_URL'].blank?

          BarOS.cache.write(CACHE_KEY, pre_sale_query)
        end

        def pre_sale_product_order_limits_suppliers
          ProductOrderLimit
            .active
            .joins(:supplier_product_order_limits)
            .merge(SupplierProductOrderLimit.active)
            .group(:id)
            .select(:id, <<-SQL.squish)
              array_agg(
                Array[
                  "#{SupplierProductOrderLimit.table_name}"."supplier_id",
                  "#{SupplierProductOrderLimit.table_name}"."current_order_qty",
                  (SELECT min(limits) FROM unnest(
                    Array [
                      #{pre_sale_min_limits(ProductOrderLimit.table_name, 'global_order_limit')},
                      #{pre_sale_min_limits(SupplierProductOrderLimit.table_name)}
                    ]::bigint[]
                  ) limits)
                ]
              ) as supplier_ids
            SQL
        end

        def pre_sale_product_order_limits_states
          ProductOrderLimit
            .active
            .joins(state_product_order_limits: :state)
            .merge(StateProductOrderLimit.active)
            .group(:id)
            .select(:id, <<-SQL.squish)
              array_agg(
                Array[
                  "#{State.table_name}"."abbreviation",
                  (SELECT min(limits) FROM unnest(
                    Array [
                      #{pre_sale_min_limits(ProductOrderLimit.table_name, 'global_order_limit')},
                      #{pre_sale_min_limits(StateProductOrderLimit.table_name)}
                    ]::bigint[]
                  ) limits)::varchar
                ]
              ) as states
          SQL
        end

        def pre_sale_min_limits(table, order_limit = 'order_limit', qty = 'current_order_qty')
          <<-SQL.squish
            case
            when "#{table}"."#{order_limit}" = 0 OR "#{table}"."#{order_limit}" IS NULL then NULL
            else "#{table}"."#{order_limit}" - "#{table}"."#{qty}"
            end
          SQL
        end

        def pre_sale_query
          # rubocop:disable Style/HashTransformValues
          PreSale
            .active
            .joins(<<-SQL.squish)
              LEFT JOIN (#{pre_sale_product_order_limits_suppliers.to_sql}) "supplier_product_order_limits"
              ON "supplier_product_order_limits"."id" = "pre_sales"."product_order_limit_id"
              LEFT JOIN (#{pre_sale_product_order_limits_states.to_sql}) "state_product_order_limits"
              ON "state_product_order_limits"."id" = "pre_sales"."product_order_limit_id"
            SQL
            .pluck(:product_id, :price, :starts_at, :supplier_ids, :states)
            .to_h do |(product_id, price, start_at, supplier_ids, states)|
              [
                product_id,
                {
                  price: price,
                  start_at: start_at,
                  states: (states || {}).to_h do |state, state_max_quantity|
                    [
                      state,
                      supplier_ids.to_h do |(supplier_id, quantity, max_quantity)|
                        [supplier_id,
                         { quantity: quantity, max_quantity: [max_quantity, state_max_quantity.to_i].compact.min }]
                      end
                    ]
                  end
                }
              ]
            end
          # rubocop:enable Style/HashTransformValues
        end
      end
    end
  end
end
