# frozen_string_literal: true

module Dashboard
  module Integration
    module ShipStation
      module Jobs
        # ShipStation ProcessFulfillmentShippedWebhook
        class ProcessFulfillmentShippedWebhook
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

            return if res['fulfillments'].empty?

            res['fulfillments'].each do |fulfillment|
              update_order(fulfillment)
            end
          end

          private

          def update_order(fulfillment)
            shipment = Shipment.joins(:supplier)
                               .where(suppliers: { id: @supplier.id })
                               .or(Shipment.where(suppliers: { delegate_supplier_id: @supplier.id }))
                               .where(external_shipment_id: fulfillment['orderId']).first

            return if shipment.nil?

            create_packages_if_needed(shipment, fulfillment['orderId'], 'fulfillments')
          end
        end
      end
    end
  end
end
