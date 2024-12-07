class SupplierAPIV2::ShipmentsEndpoint::PackagesEndpoint::LabelsEndpoint < BaseAPIV2
  helpers do
    def ship_engine_adapter
      @ship_engine_adapter ||= ShipEngineAdapter.new
    end

    def create_packages
      shipments_payload = params[:shipments]
      @packages = []

      shipments_payload.each do |shipment|
        s = current_supplier.shipments.find_by(uuid: shipment.fetch('uuid'))
        s ||= Shipment.where(supplier_id: current_supplier_ids).find_by(uuid: shipment.fetch('uuid'))

        error!('Shipment not found', 404) if s.nil?

        shipment.fetch('packages').each do |package|
          p = s.packages.create!(
            carrier: package.fetch('carrier')
          )

          p.create_ship_engine_detail!(
            dimensions: package.fetch('package').fetch('dimensions'),
            weight: package.fetch('package').fetch('weight'),
            confirmation: package.fetch('confirmation')
          )

          @packages.push(p.reload)
        end
      end
    end
  end

  namespace :orders do
    namespace :packages do
      namespace :labels do
        before do
          authorize!
        end

        desc 'Get labels from shipments'
        get do
          pdf = CombinePDF.new
          file_name = "labels_#{DateTime.now}"

          shipment_ids = Shipment.where(uuid: params[:shipment_ids]).ids

          Package.where(shipment_id: shipment_ids).where.not(label_url: nil).each do |package|
            url = URI.parse(package.label_url)
            response = Net::HTTP.get_response(url)
            pdf << CombinePDF.parse(response.body) if response.is_a?(Net::HTTPSuccess)
          end

          content_type 'application/pdf'
          header['Content-Disposition'] = "attachment; filename=#{file_name}"
          env['api.format'] = :binary
          status 201
          pdf.to_pdf
        end

        params do
          requires :shipments, type: Array, allow_blank: false do
            requires :uuid, type: String, allow_blank: false
            requires :packages, type: Array, allow_blank: false do
              requires :carrier, type: String, allow_blank: false
              requires :package, type: Hash, allow_blank: false do
                requires :dimensions, type: Hash, allow_blank: false do
                  requires :length, type: String, allow_blank: false
                  requires :width, type: String, allow_blank: false
                  requires :height, type: String, allow_blank: false
                end

                requires :weight, type: Hash, allow_blank: false do
                  requires :value, type: String, allow_blank: false
                  requires :unit, type: String, allow_blank: false
                end
              end
              requires :confirmation, type: String, allow_blank: false
            end
          end
        end

        desc 'Create labels into ShipEngine'
        post do
          create_packages

          @packages.each do |p|
            begin
              create_label_resp_body = ship_engine_adapter.create_label(package: p).body
            rescue ShipEngineAdapter::UnsuccessfulResponseError,
                   ShipEngineAdapter::UnsupportedCarrierError,
                   ShipEngineAdapter::CarrierAccountNotConnectedError,
                   ArgumentError => e
              package_ids_to_delete = Package::ShipEngineDetail.where(package_id: @packages.pluck(:id), ship_engine_label_id: nil).pluck(:package_id)
              Package.where(id: package_ids_to_delete).destroy_all

              error!(e.message, 400)
            end

            tracking_number = create_label_resp_body.fetch('tracking_number')

            p.update(
              label_url: create_label_resp_body.fetch('label_download').fetch('pdf'),
              tracking_number: tracking_number
            )

            p.ship_engine_detail.update(
              ship_engine_shipment_id: create_label_resp_body.fetch('shipment_id'),
              ship_engine_label_id: create_label_resp_body.fetch('label_id')
            )

            after_ship_create_tracking_service = AfterShip::CreateTrackingService.new(p, true)
            after_ship_create_tracking_service.call

            error!(after_ship_create_tracking_service.error_message, 400) if after_ship_create_tracking_service.error_message.present?
          end

          status 201
        end
      end
    end
  end
end
