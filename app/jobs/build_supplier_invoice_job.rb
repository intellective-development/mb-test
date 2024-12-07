class BuildSupplierInvoiceJob < ActiveJob::Base
  queue_as :internal

  def perform(invoice_id)
    invoice = InvoicingLedgerItem.includes(line_items: :shipment_amount).find_by_uuid(invoice_id)
    invoice.build!
  end
end
