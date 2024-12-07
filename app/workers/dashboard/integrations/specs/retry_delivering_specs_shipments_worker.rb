module Dashboard
  module Integrations
    class Specs::RetryDeliveringSpecsShipmentsWorker
      include Sidekiq::Worker
      include WorkerErrorHandling

      TECHNICAL_ISSUE_NOTE = '-> Error while delivering shipment. It needs a manual check due to a technical issue.'.freeze

      sidekiq_options queue: 'backfill', lock: :until_executing

      def perform_with_error_handling
        Rails.logger.info("Starting RetryDeliveringSpecsShipmentsWorker for #{not_delivered_shipments.size} shipments.")

        ds = Dashboard::Integration::SpecsDashboard.new
        not_delivered_shipments.each do |shipment|
          next if technical_issue_comment?(shipment)

          begin
            ds.change_order_status(shipment, 'delivered')
            shipment.reload

            raise Dashboard::Integration::Specs::Error::UnknownError, "Shipment #{shipment.id} wasn't marked as delivered" if shipment.comments.where('note = ?', "Spec's: -> Spec's was notified of shipment status change: completed").empty?
          rescue StandardError => e
            add_technical_issue_note(shipment)
            Rails.logger.info("[Specs] Error when retry delivering shipment #{shipment.id}: #{e}")
          end
        end

        Rails.logger.info('Finished RetryDeliveringSpecsShipmentsWorker.')
      end

      def add_technical_issue_note(shipment)
        Dashboard::Integration::Specs::Notes.add_note(shipment, TECHNICAL_ISSUE_NOTE, !Feature[:disable_asana_notifications_for_specs].enabled?)
      end

      def not_delivered_shipments
        supplier_ids = Dashboard::Integration::SpecsDashboard.get_supplier_ids

        Shipment.where.not(
          id: Shipment.joins(:comments)
                      .where(
                        state: 'delivered',
                        supplier: supplier_ids
                      )
                      .where('comments.note = ?', "Spec's: -> Spec's was notified of shipment status change: completed")
        ).where(
          state: 'delivered', supplier: supplier_ids
        ).where.not(
          external_shipment_id: nil
        ).where('shipments.delivered_at > ?', 2.days.ago)
      end

      def technical_issue_comment?(shipment)
        shipment.comments.where(note: "Spec's: #{TECHNICAL_ISSUE_NOTE}").present?
      end
    end
  end
end
