class GenerateSupplierInvoiceJob < ActiveJob::Base
  queue_as :invoicing

  def perform(supplier_id, month, business_id, old_invoice_id = nil)
    if old_invoice_id.present?
      old_invoice = SupplierInvoice.find(old_invoice_id)
      old_invoice.void! if old_invoice && old_invoice.status == 'finalized'
    end

    supplier = Supplier.find(supplier_id)

    start_date = month.to_date
    start_date = Time.zone.local(start_date.year, start_date.month, 1)
    end_date = (start_date + 1.month)

    supplier.start_invoice(business_id, start_date, end_date)
  end
end
