class SupplierAPIV2::SupplierEndpoint::ShipmentsEndpoint < BaseAPIV2
  before do
    authorize!
  end

  namespace :supplier do
    namespace :shipments do
      desc "Returns current supplier's unconfirmed shipments."
      get :unconfirmed do
        unconfirmed_shipments = Shipment.joins(:order)
                                        .where(supplier_id: current_supplier_ids)
                                        .where(
                                          'orders.state in (:order_visible_states) AND '\
                                          'shipments.state in (:unconfirmed_state) OR '\
                                          '(shipments.state = :scheduled_state AND shipments.scheduled_for <= :scheduling_cutoff)',
                                          unconfirmed_state: %w[ready_to_ship paid],
                                          order_visible_states: Order::SUPPLIER_VISIBLE_STATES,
                                          scheduled_state: 'scheduled',
                                          scheduling_cutoff: Time.zone.now.in_time_zone(current_supplier.timezone) + Shipment::SCHEDULING_BUFFER.hours
                                        )

        present unconfirmed_shipments, with: SupplierAPIV2::Entities::ShipmentListItem
      end
    end
  end
end
