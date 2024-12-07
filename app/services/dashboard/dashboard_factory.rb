# frozen_string_literal: true

module Dashboard
  # DashboardFactory
  class DashboardFactory
    def self.build(supplier)
      case supplier.dashboard_type
      when Supplier::DashboardType::MINIBAR
        Integration::MinibarDashboard.new
      when Supplier::DashboardType::SEVEN_ELEVEN
        Integration::SevenElevenDashboard.new
      when Supplier::DashboardType::SPECS
        Integration::SpecsDashboard.new
      when Supplier::DashboardType::BEVMAX
        Integration::BevmaxDashboard.new
      when Supplier::DashboardType::THREE_JMS
        Integration::ThreeJMSDashboard.new supplier
      when Supplier::DashboardType::SHIP_STATION
        Integration::ShipStationDashboard.new supplier
      else
        raise 'Unsupported dashboard type!'
      end
    end
  end
end
