class Shipment::UpdateInventoryWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options queue: 'internal', lock: :until_executing

  def perform_with_error_handling(shipment_id)
    ActiveRecord::Base.transaction do
      Shipment.includes(order_items: [:inventory]).find(shipment_id).tap do |shipment|
        shipment.order_items.each(&:update_inventory)
      end
    end
  end
end
