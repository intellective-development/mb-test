# frozen_string_literal: true

module Dashboard
  module Integration
    module ShipStation
      module Jobs
        # ShipStationWebhookHelpers
        module ShipStationWebhookHelpers
          # @param [Shipment] shipment
          # @param [String] external_shipment_id
          # @param [String] entity - 'shipments' or 'fulfillments'
          def create_packages_if_needed(shipment, external_shipment_id, entity)
            return if entity.empty?

            response = @adapter.send("get_order_#{entity}", external_shipment_id)
            packages = response[entity] || []
            packages.each do |package|
              create_package_if_not_exists(shipment, package)
            end
          end

          def get_package_by_tracking_number(shipment, reference)
            shipment.packages.find_by(tracking_number: reference)
          end

          def create_package(shipment, data)
            tracking_number = data['trackingNumber']
            package = get_package_by_tracking_number(shipment, tracking_number)
            if data['voided'] || data['voidDate'].present?
              package.destroy if package.present?
              return
            end

            return if package.present?

            Rails.logger.warn("[ShipStation Webhook] Package has already been created to shipment #{shipment.id}") if package.present?

            if tracking_number
              package = shipment.packages.create(tracking_number: tracking_number)
              AfterShip::CreateTrackingService.new(package, true).call
              Dashboard::Integration::ShipStation::Notes.add_note(shipment, "<- Package with tracking number #{tracking_number} has been created")
            else
              Rails.logger.error("[ShipStation Webhook] No tracking details provided for Shipment #{shipment.id}: #{data}")
            end
          rescue StandardError => e
            Rails.logger.error("#{e.message}\n#{e.backtrace&.join("\n")}")
            raise e
          end

          def create_package_if_not_exists(shipment, data)
            return if data.nil? || data['trackingNumber'].empty?

            create_package(shipment, data) if get_package_by_tracking_number(shipment, data['trackingNumber']).nil?
          end
        end
      end
    end
  end
end
