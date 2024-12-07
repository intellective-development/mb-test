class SupplierAPIV2::ShipmentEndpoint::PackagesEndpoint < BaseAPIV2
  namespace :order do
    before do
      authorize!
    end

    route_param :shipment_uuid do
      before do
        @shipment = current_supplier.shipments.find_by(uuid: params[:shipment_uuid])
        @shipment ||= Shipment.where(supplier_id: current_supplier_ids).find_by(uuid: params[:shipment_uuid])

        error!('Order not found', 404) if @shipment.nil?
      end

      namespace :packages do
        desc 'Create a package.'
        params do
          requires :tracking_number, type: String
        end
        post do
          error!('Tracking number should be present', 400) if params[:tracking_number].blank?

          tracking_number = params[:tracking_number]

          @package = @shipment.packages.build(
            tracking_number: tracking_number
          )

          error!("An error occurred while creating a package: #{@package.errors.full_messages.to_sentence}", 422) unless @package.save

          after_ship_create_tracking_service = AfterShip::CreateTrackingService.new(@package, true)
          after_ship_create_tracking_service.call

          error!(after_ship_create_tracking_service.error_message, 400) if after_ship_create_tracking_service.error_message.present?

          status 201
        end

        route_param :package_uuid do
          before do
            @package = @shipment.packages.find_by(uuid: params[:package_uuid])

            error!('Package not found', 404) if @package.nil?
          end

          desc 'Delete a package.'
          delete do
            if @package.destroy
              body false
            else
              error!('An error occurred while deleting the given package', 422)
            end
          end
        end
      end
    end
  end
end
