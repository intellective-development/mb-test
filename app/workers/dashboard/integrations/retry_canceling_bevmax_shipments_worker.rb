module Dashboard
  module Integrations
    class RetryCancelingBevmaxShipmentsWorker
      include Sidekiq::Worker
      include WorkerErrorHandling

      TECHNICAL_ISSUE_NOTE = '-> Error while canceling shipment order. It needs a manual check due to a technical issue.'.freeze

      sidekiq_options queue: 'backfill', lock: :until_executing

      def perform_with_error_handling
        Rails.logger.info("Starting RetryCancelingBevmaxShipmentsWorker for #{not_canceled_shipments.size} shipments.")

        ds = Dashboard::Integration::BevmaxDashboard.new
        not_canceled_shipments.each do |shipment|
          next if technical_issue_comment?(shipment)

          begin
            ds.cancel_order(shipment)
            shipment.reload

            raise Dashboard::Integration::Bevmax::Error::UnknownError, "Shipment #{shipment.id} wasn't marked as canceled" if shipment.comments.where("note = 'BevMax: -> Shipment canceled' OR note LIKE 'BevMax: <- Shipment canceled.%'").empty?
          rescue StandardError
            add_technical_issue_note(shipment)
            Rails.logger.info("[Bevmax] Error when retry canceling shipment #{shipment.id}: #{e}")
          end
        end

        Rails.logger.info('Finished RetryCancelingBevmaxShipmentsWorker.')
      end

      def add_technical_issue_note(shipment)
        Dashboard::Integration::Bevmax::Notes.add_note(shipment, TECHNICAL_ISSUE_NOTE, true)
      end

      def not_canceled_shipments
        supplier_ids = Supplier.where(dashboard_type: Supplier::DashboardType::BEVMAX).pluck(:id)
        supplier_ids += Supplier.where(delegate_supplier_id: supplier_ids).pluck(:id)

        Shipment.where.not(
          id: Shipment.joins(:comments)
                      .where(
                        state: 'canceled',
                        supplier: supplier_ids
                      )
          .where("comments.note LIKE 'BevMax: -> Shipment canceled%' OR comments.note LIKE 'BevMax: <- Shipment canceled.%'")
        ).where(
          state: 'canceled', supplier: supplier_ids
        ).where('shipments.external_shipment_id IS NOT NULL')
      end

      def technical_issue_comment?(shipment)
        shipment.comments.where(note: "BevMax: #{TECHNICAL_ISSUE_NOTE}").present?
      end
    end
  end
end
