module Suppliers
  module SupplierShipStates
    class Save
      def initialize(supplier, ship_states_by_category_id)
        @supplier                   = supplier
        @ship_states_by_category_id = ship_states_by_category_id || {}
      end

      def call
        ids = execute_query(values_query)
        supplier.supplier_ship_states.where.not(id: ids).delete_all

        self
      end

      private

      attr_reader :supplier, :ship_states_by_category_id

      def execute_query(values)
        return [] if values.empty?

        ActiveRecord::Base.connection.execute(sql(values.join(', '))).pluck('id')
      end

      def values_query
        ship_states_by_category_id.flat_map do |ship_level, values|
          values.map do |ship_category_id, states|
            ActiveRecord::Base.send(
              :sanitize_sql_array, [values_sql, build_sql_values(ship_category_id, ship_level, states)]
            )
          end
        end
      end

      def build_sql_values(ship_category_id, ship_level, states)
        { supplier_id: supplier.id, ship_category_id: ship_category_id, ship_level: ship_level, states: states.to_json }
      end

      def values_sql
        '(:supplier_id, :ship_category_id, :ship_level, :states, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)'
      end

      def sql(values_query)
        <<-SQL
          INSERT INTO supplier_ship_states(supplier_id, ship_category_id, ship_level, states, created_at, updated_at)
          VALUES #{values_query}
          ON CONFLICT (supplier_id, ship_category_id, ship_level)
          DO UPDATE SET states=excluded.states, updated_at=excluded.updated_at
          RETURNING id
        SQL
      end
    end
  end
end
