module Dashboard
  module Integrations
    class Specs::RetryPlacingSpecsShipmentsWorker
      include Sidekiq::Worker
      include WorkerErrorHandling

      TECHNICAL_ISSUE_NOTE = '-> Error while placing shipment order. It needs a manual check due to a technical issue.'.freeze

      sidekiq_options queue: 'backfill', lock: :until_executing

      def perform_with_error_handling
        ds = Dashboard::Integration::SpecsDashboard.new

        Rails.logger.info("Starting RetryPlacingSpecsShipmentsWorker for #{not_placed_shipments.size} shipments.")

        not_placed_shipments.each do |shipment|
          next if technical_issue_comment?(shipment)

          ds.place_order(shipment)

          shipment.reload
          add_technical_issue_note(shipment) if shipment.external_shipment_id.nil?
        end

        Rails.logger.info('Finished RetryPlacingSpecsShipmentsWorker.')
      end

      def add_technical_issue_note(shipment)
        Dashboard::Integration::Specs::Notes.add_note(shipment, TECHNICAL_ISSUE_NOTE, !Feature[:disable_asana_notifications_for_specs].enabled?)
      end

      def not_placed_shipments
        supplier_ids = Dashboard::Integration::SpecsDashboard.get_supplier_ids

        Shipment.joins(:supplier)
                .where(
                  state: %w[paid ready_to_ship confirmed pre_sale back_order],
                  external_shipment_id: nil,
                  supplier_id: supplier_ids,
                  created_at: 48.hours.ago..DateTime.now
                )
                .where(Shipment.arel_table[:updated_at].lt(1.hour.ago))
      end

      def technical_issue_comment?(shipment)
        shipment.comments.where(note: "Spec's: #{TECHNICAL_ISSUE_NOTE}").present?
      end
    end
  end
end
