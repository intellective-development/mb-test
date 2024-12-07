module NoShipStates
  class Save
    include SentryNotifiable

    attr_reader :params

    def initialize(params)
      @params = params
    end

    def call
      ids = execute_query!(values_query)
      NoShipState.where.not(id: ids).update_all(states: [])

      trigger_bar_os_sync

      self
    end

    def success?
      @success
    end

    private

    def execute_query!(values)
      return [] if values.blank?

      ActiveRecord::Base.connection.execute(sql(values.join(', '))).pluck('id')
    end

    def values_query
      params[:states_by_category].to_h.map do |ship_category_id, states|
        ActiveRecord::Base.send(
          :sanitize_sql_array, [insert_values_sql, build_sql_values(ship_category_id, states)]
        )
      end
    end

    def insert_values_sql
      '(:ship_category_id, :states, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)'
    end

    def build_sql_values(ship_category_id, states)
      { ship_category_id: ship_category_id, states: states.to_json }
    end

    def sql(values_query)
      <<-SQL
        INSERT INTO no_ship_states(ship_category_id, states, created_at, updated_at)
        VALUES #{values_query}
        ON CONFLICT (ship_category_id)
        DO UPDATE SET states=excluded.states, updated_at=excluded.updated_at
        RETURNING id
      SQL
    end

    def trigger_bar_os_sync
      return if ENV['KAFKA_KIT_ENABLED'].to_s != 'true'

      BarOSAPI::Admin::V1::NoShipStates.sync
    rescue Faraday::Error => e
      notify_sentry_and_log(e, "Error on trigger BarOS no ship state sync, #{e.message}")
    end
  end
end
