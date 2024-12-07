class Supplier
  module DashboardType
    MINIBAR = 'MINIBAR'.freeze
    SEVEN_ELEVEN = 'SEVEN_ELEVEN'.freeze
    SPECS = 'SPECS'.freeze
    BEVMAX = 'BEVMAX'.freeze
    THREE_JMS = 'THREE_JMS'.freeze
    SHIP_STATION = 'SHIP_STATION'.freeze
    DASHBOARD_TYPES = [MINIBAR, SEVEN_ELEVEN, SPECS, BEVMAX, THREE_JMS, SHIP_STATION].freeze

    HUMAN_FRIENDLY_NAMES = {
      MINIBAR: 'Minibar Supplier Dashboard',
      SEVEN_ELEVEN: '7NOW - 7-Eleven Integration',
      SPECS: 'Spec\'s Integration',
      BEVMAX: 'Bevmax\'s Integration',
      THREE_JMS: '3JMS Integration',
      SHIP_STATION: 'ShipStation Integration'
    }.freeze

    def custom_dashboard?
      dashboard_type != MINIBAR
    end

    def dashboard_name
      HUMAN_FRIENDLY_NAMES.fetch(dashboard_type.to_sym, dashboard_type.titleize)
    end

    def self.select_props
      DASHBOARD_TYPES.map { |d| [HUMAN_FRIENDLY_NAMES.fetch(d.to_sym, d.titleize), d] }
    end
  end
end
