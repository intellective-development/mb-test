# frozen_string_literal: true

module Dashboard
  module Integration
    module ShipStation
      module Jobs
        # ShipStation ProcessOrderNotifyWebhook
        class ProcessOrderNotifyWebhook
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

            return if res['orders'].empty?

            res['orders'].each do |order|
              update_order(order)
            end
          end

          private

          def update_order(order_data)
            order_id = order_data['orderId']
            shipment = Shipment.joins(:supplier)
                               .where(suppliers: { id: @supplier.id })
                               .or(Shipment.where(suppliers: { delegate_supplier_id: @supplier.id }))
                               .where(external_shipment_id: order_id).first
            order_status = order_data['orderStatus']

            return if shipment.nil?

            case order_status
            when 'cancelled'
              shipment.cancel if shipment.can_transition_to?(:canceled)
              Dashboard::Integration::ShipStationDashboard.mark_shipment_canceled(shipment.id, @supplier.id)
            when 'shipped'
              shipment.start_delivery! if shipment.confirmed?
              create_packages_if_needed(shipment, order_id, 'shipments')
              create_packages_if_needed(shipment, order_id, 'fulfillments')
            end
          end
        end
      end
    end
  end
end
