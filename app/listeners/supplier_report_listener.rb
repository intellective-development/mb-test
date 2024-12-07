class SupplierReportListener < Minibar::Listener::Base
  subscribe_to SupplierReport

  def supplier_report_created(supplier_report)
    GenerateSupplierReportWorker.perform_async(supplier_report.id)
  end
end
