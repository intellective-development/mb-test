module Dashboard
  module Integrations
    class RetryCancelingThreejmsShipmentsWorker
      include Sidekiq::Worker
      include WorkerErrorHandling

      TECHNICAL_ISSUE_NOTE = '-> Error while canceling shipment order. It needs a manual check due to a technical issue.'.freeze

      sidekiq_options queue: 'backfill', retry: false, lock: :until_executing

      def perform_with_error_handling
        errors = []

        Rails.logger.info("Starting RetryCancelingThreejmsShipmentsWorker for #{not_canceled_shipments.size} shipments.")

        not_canceled_shipments.each do |shipment|
          next if technical_issue_comment?(shipment)

          begin
            ds = Dashboard::Integration::ThreeJMSDashboard.new(shipment.effective_supplier)
            ds.cancel_order(shipment)

            shipment.reload

            raise Dashboard::Integration::ThreeJMS::Error::UnknownError, "Shipment #{shipment.id} wasn't marked as canceled" if shipment.comments.where("note = '3JMS: -> Shipment canceled' OR note LIKE '3JMS: <- Shipment canceled.%'").empty?
          rescue StandardError => e
            add_technical_issue_note(shipment)
            Rails.logger.info("[3JMS] Error when retry canceling shipment #{shipment.id}: #{e}")
            errors << e
          end
        end

        Rails.logger.info('Finished RetryCancelingThreejmsShipmentsWorker.')

        # Test to get rid of Sentry umbrella stuff (btw retry is false)
        raise StandardError, "[3JMS] Errors when retrying canceling orders: \n #{errors.map(&:message).join("\n")}" if errors.any?
      end

      def add_technical_issue_note(shipment)
        Dashboard::Integration::ThreeJMS::Notes.add_note(shipment, TECHNICAL_ISSUE_NOTE, true, [AsanaService::CANCELLATION_ISSUE_TAG_ID])
      end

      def not_canceled_shipments
        supplier_ids = Supplier.where(dashboard_type: Supplier::DashboardType::THREE_JMS).pluck(:id)
        supplier_ids += Supplier.where(delegate_supplier_id: supplier_ids).pluck(:id)

        Shipment.where.not(
          id: Shipment.joins(:comments)
                      .where("comments.note LIKE '3JMS: -> Shipment canceled%' OR comments.note LIKE '3JMS: <- Shipment canceled.%'")
                      .where(
                        state: 'canceled',
                        supplier: supplier_ids
                      )
        ).where(
          state: 'canceled', supplier: supplier_ids
        ).where('shipments.external_shipment_id IS NOT NULL')
      end

      def technical_issue_comment?(shipment)
        shipment.comments.where(note: "3JMS: #{TECHNICAL_ISSUE_NOTE}").present?
      end
    end
  end
end
