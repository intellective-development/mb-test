# frozen_string_literal: true

# Endpoint to bulk print shipment invoices
class SupplierAPIV3::ShipmentsEndpoint::InvoiceEndpoint < BaseAPIV3
  namespace :orders do
    namespace :invoices do
      desc 'Get invoice as html for multiple orders'
      params do
        requires :uuids, type: Array, allow_blank: false
      end
      get :pdf_html do
        @shipments = Shipment.where(supplier_id: current_supplier_ids.push(current_supplier.id)).where(uuid: params[:uuids])

        resp = ''

        @shipments.each do |shipment|
          resp += ShipmentInvoiceService.new(shipment).generate_invoice_html
        end

        resp
      end
    end
  end
end
