class AvalaraInvoiceWorker
  include Sidekiq::Worker
  include WorkerErrorHandling
  include SentryNotifiable

  sidekiq_options retry: 5,
                  queue: 'notifications_shipment',
                  lock: :until_and_while_executing

  def perform_with_error_handling(id)
    @shipment = Shipment.find(id)

    return if @shipment.invoiced?

    begin
      tax_service = Avalara::TaxService.new(@shipment)
      invoice = tax_service.submit_invoice
      transaction_code = invoice.get_transaction_code

      if invoice.get_total == shipment_invoiced_value
        tax_service.confirm_invoice(transaction_code)
        create_comment("AvaTax: #{@shipment.supplier.display_name} - invoiced. Transaction Code: #{transaction_code}")
        @shipment.update!(invoice_status: :invoiced)
      else
        error_message = "AvaTax: #{@shipment.supplier.display_name} - could not invoice. Mismatch detected between Minibar ($#{shipment_invoiced_value}) and Avalara ($#{invoice.get_total.to_f}). Transaction Code: #{transaction_code}"
        create_comment(error_message)
        @shipment.update!(invoice_status: :error)
        Rails.logger.error(error_message)
      end
    rescue StandardError => e
      notify_sentry_and_log(e, "Error invoicing shipment #{e.message}", { tags: { order_id: @shipment.order.id } })
      @shipment.update!(invoice_status: :error)
    end
  end

  private

  def shipment_invoiced_value
    # sub_total +
    # tax_total (order_items_tax + shipping_tax) +
    # tip_share +
    # fees_total_without_engraving (shipping_fee + bottle_deposit_fees + bag_fee + retail_delivery_fee + engraving_fee_without_discounts)
    return @shipment.total.to_f.round(2) if Feature[:split_avalara_transaction].enabled?

    (@shipment.total + @shipment.order.service_fee).to_f.round(2)
  end

  def create_comment(message)
    @shipment.order.comments.create({ note: message, posted_as: :minibar })
  end
end
