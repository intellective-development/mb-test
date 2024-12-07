class ShipmentAddressUpdateWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal'

  def perform_with_error_handling(address_id, user_id)
    shipments = Shipment.joins('JOIN orders ON shipments.order_id = orders.id').where("orders.ship_address_id = #{address_id} AND orders.state IS NOT NULL AND orders.completed_at IS NOT NULL").where.not(state: 'delivered')

    update_dashboard_integrations(shipments)
    update_invoices(shipments, user_id)
  end

  def update_invoices(shipments, user_id)
    shipments.find_each do |shipment|
      shipment.comments.create(note: 'This order has an updated address.  We suggest you reprint the order slip which has been updated with the correct information', created_by: user_id)
    end
  end

  def update_dashboard_integrations(shipments)
    shipments.each do |shipment|
      shipment.broadcast_event(:shipment_address_updated)
    end
  end
end
