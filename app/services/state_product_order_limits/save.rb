module StateProductOrderLimits
  class Save
    attr_reader :product_order_limit, :params

    def initialize(product_order_limit, params)
      @product_order_limit = product_order_limit
      @params              = params
    end

    def call
      ids = execute_query(values_query)

      @success = StateProductOrderLimit.where(product_order_limit: product_order_limit)
                                       .where.not(id: ids)
                                       .delete_all

      self
    end

    def success?
      @success
    end

    private

    def execute_query(values)
      return [] if values.empty?

      ActiveRecord::Base.connection.execute(sql(values.join(', '))).pluck('id')
    end

    def values_query
      params.map do |state_id, order_limit|
        ActiveRecord::Base.send(
          :sanitize_sql_array, [insert_values_sql, build_sql_values(state_id, order_limit)]
        )
      end
    end

    def insert_values_sql
      <<-SQL
        (:product_order_limit_id, :state_id, :order_limit, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      SQL
    end

    def build_sql_values(state_id, order_limit)
      { product_order_limit_id: product_order_limit.id, state_id: state_id, order_limit: (order_limit.presence || -1) }
    end

    def sql(values_query)
      <<-SQL
        INSERT INTO state_product_order_limits(product_order_limit_id, state_id, order_limit, created_at, updated_at)
        VALUES #{values_query}
        ON CONFLICT (product_order_limit_id, state_id)
        DO UPDATE SET order_limit=excluded.order_limit#{' '}
        RETURNING id
      SQL
    end
  end
end
