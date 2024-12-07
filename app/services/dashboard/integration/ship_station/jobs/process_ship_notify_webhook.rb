# frozen_string_literal: true

module Dashboard
  module Integration
    module ShipStation
      module Jobs
        # ShipStation ProcessShipNotifyWebhook
        class ProcessShipNotifyWebhook
          include Sidekiq::Job
          include ShipStation::ApiMethods
          include Dashboard::DashboardJobs
          include ShipStationWebhookHelpers

          sidekiq_options queue: 'notifications_shipment',
                          lock: :until_executed,
                          retry: 3

          def perform_with_rate_limit(supplier_id, resource_url)
            @supplier = Supplier.find_by(id: supplier_id)

            return if @supplier.nil? || @supplier.ship_station_credential.nil?

            @adapter = get_integration(@supplier)
            res = @adapter.get_webhook_resource_content(resource_url)

            return if res['shipments'].empty?

            res['shipments'].each do |shipment|
              update_order(shipment)
            end
          end

          private

          def update_order(ss_shipment)
            shipment = Shipment.joins(:supplier)
                               .where(suppliers: { id: @supplier.id })
                               .or(Shipment.where(suppliers: { delegate_supplier_id: @supplier.id }))
                               .where(external_shipment_id: ss_shipment['orderId']).first

            return if shipment.nil?

            create_packages_if_needed(shipment, ss_shipment['orderId'], 'shipments')
          end
        end
      end
    end
  end
end
