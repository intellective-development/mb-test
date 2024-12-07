module Dashboard
  class DashboardService
    def self.notify(shipment, state = nil)
      state ||= shipment.state

      action = 'change_order_status'

      if shipment.customer_placement_standard?
        action = case state
                 when 'ready_to_ship'
                   'place_order'
                 when 'canceled'
                   'cancel_order'
                 else
                   action
                 end
      elsif state == 'canceled'
        action = 'cancel_order'
      elsif shipment.effective_supplier.dashboard_type == Supplier::DashboardType::SHIP_STATION
        return if %w[pre_sale back_order].include?(state)

        action = 'place_order' if state == 'ready_to_ship'
      elsif %w[pre_sale back_order].include?(state)
        action = 'place_order'
      end

      dashboard = DashboardFactory.build(shipment.effective_supplier)

      if action == 'change_order_status'
        dashboard.public_send action, shipment, state
      else
        dashboard.public_send action, shipment
      end
    end

    def self.update_order_items(shipment)
      Integration::ThreeJMSDashboard.update_order_items(shipment) if shipment.effective_supplier.dashboard_type == Supplier::DashboardType::THREE_JMS
    end

    def self.update_address(shipment)
      Integration::ThreeJMSDashboard.update_order_address(shipment) if shipment.effective_supplier.dashboard_type == Supplier::DashboardType::THREE_JMS
    end

    # Only cancels the shipment on the third party dashboard
    # @param shipment [Shipment]
    def self.cancel_shipment(shipment)
      Integration::ThreeJMSDashboard.new(shipment.effective_supplier).cancel_order(shipment) if shipment.effective_supplier.dashboard_type == Supplier::DashboardType::THREE_JMS
      Integration::ShipStationDashboard.new(shipment.effective_supplier).cancel_order(shipment) if shipment.effective_supplier.dashboard_type == Supplier::DashboardType::SHIP_STATION
      shipment.update(external_shipment_id: nil)
    end

    # Only places the shipment on the third party dashboard
    # @param shipment [Shipment]
    def self.redo_place_pre_sale_shipment(shipment)
      Integration::ThreeJMSDashboard.new(shipment.effective_supplier).place_order(shipment) if shipment.effective_supplier.dashboard_type == Supplier::DashboardType::THREE_JMS
      Integration::ShipStationDashboard.new(shipment.effective_supplier).place_order(shipment) if shipment.effective_supplier.dashboard_type == Supplier::DashboardType::SHIP_STATION
    end
  end
end
