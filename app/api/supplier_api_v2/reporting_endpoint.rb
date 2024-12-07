class SupplierAPIV2::ReportingEndpoint < BaseAPIV2
  namespace :reports do
    content_type :csv, 'text/csv'
    default_format :csv

    get do
      reports = SupplierReport.where(supplier_id: current_supplier_ids).order(created_at: :desc).limit(15)

      header 'X-Total', reports.count.to_s
      header 'X-Total-Pages', '1'
      present reports, with: SupplierAPIV2::Entities::Report
    end
    params do
      requires :report_type, type: String
      optional :end_date,    type: String
      optional :start_date,  type: String
    end
    post do
      report = current_supplier.reports.create(report_type: params[:report_type],
                                               end_date: params[:end_date],
                                               start_date: params[:start_date],
                                               open_orders: params[:open_orders],
                                               shipping_only: params[:shipping_only],
                                               delivery_only: params[:delivery_only])

      present report, with: SupplierAPIV2::Entities::Report
    end
  end
end
