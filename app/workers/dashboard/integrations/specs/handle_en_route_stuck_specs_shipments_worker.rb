module Dashboard
  module Integrations
    class Specs::HandleEnRouteStuckSpecsShipmentsWorker
      include Sidekiq::Worker
      include WorkerErrorHandling

      sidekiq_options queue: 'backfill', lock: :until_executing

      def perform_with_error_handling
        Rails.logger.info("Starting HandleEnRouteStuckSpecsShipmentsWorker for #{stuck_shipments.size} shipments.")

        ds = Dashboard::Integration::SpecsDashboard.new
        stuck_shipments.each do |shipment|
          shipment.deliver!
        rescue StandardError => e
          Rails.logger.info("[Specs] Error when retry canceling shipment #{shipment.id}: #{e}")
        end

        Rails.logger.info('Finished HandleEnRouteStuckSpecsShipmentsWorker.')
      end

      def stuck_shipments
        supplier_ids = Dashboard::Integration::SpecsDashboard.get_supplier_ids

        Shipment.joins(:shipment_transitions)
                .where(
                  state: 'en_route',
                  supplier: supplier_ids
                )
                .where(state: 'en_route', supplier: supplier_ids)
                .where.not(external_shipment_id: nil, delivery_service_order: nil)
                .where('shipment_transitions.to_state = ? AND shipment_transitions.most_recent = ? AND shipment_transitions.created_at <= ?', 'en_route', true, 4.hours.ago)
      end
    end
  end
end
