module Dashboard
  module Integrations
    class RetryPlacingThreejmsShipmentsWorker
      include Sidekiq::Worker
      include WorkerErrorHandling

      TECHNICAL_ISSUE_NOTE = '-> Error while placing shipment order. It needs a manual check due to a technical issue.'.freeze

      sidekiq_options queue: 'backfill', lock: :until_executing

      def perform_with_error_handling
        Rails.logger.info("Starting RetryPlacingThreejmsShipmentsWorker for #{not_placed_shipments.size} shipments.")

        not_placed_shipments.each do |shipment|
          next if technical_issue_comment?(shipment)

          ds = Dashboard::Integration::ThreeJMSDashboard.new(shipment.effective_supplier)
          ds.place_order(shipment)

          shipment.reload
          add_technical_issue_note(shipment) if shipment.external_shipment_id.nil?
        end

        Rails.logger.info('Finished RetryPlacingThreejmsShipmentsWorker.')
      end

      def add_technical_issue_note(shipment)
        Dashboard::Integration::ThreeJMS::Notes.add_note(shipment, TECHNICAL_ISSUE_NOTE, true)
      end

      def not_placed_shipments
        supplier_ids = Supplier.where(dashboard_type: Supplier::DashboardType::THREE_JMS).pluck(:id)
        supplier_ids.concat Supplier.where(delegate_supplier_id: supplier_ids).pluck(:id)

        Shipment.joins(:supplier)
                .includes(:supplier)
                .where(
                  state: %w[paid ready_to_ship confirmed pre_sale back_order],
                  external_shipment_id: nil,
                  supplier_id: supplier_ids,
                  created_at: 48.hours.ago..DateTime.now
                ).where(Shipment.arel_table[:updated_at].lt(1.hour.ago))
      end

      def technical_issue_comment?(shipment)
        shipment.comments.where(note: "3JMS: #{TECHNICAL_ISSUE_NOTE}").present?
      end
    end
  end
end
