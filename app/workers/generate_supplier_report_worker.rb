class GenerateSupplierReportWorker
  include Sidekiq::Worker
  include WorkerErrorHandling

  sidekiq_options retry: true,
                  queue: 'internal'

  def perform_with_error_handling(supplier_report_id)
    SupplierReport.find(supplier_report_id).tap do |supplier_report|
      supplier_report.generate_report if supplier_report.pending?
    end
  end
end
