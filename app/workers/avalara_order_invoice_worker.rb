class AvalaraOrderInvoiceWorker
  include Sidekiq::Worker
  include WorkerErrorHandling
  include SentryNotifiable

  sidekiq_options retry: 5,
                  queue: 'notifications_shipment',
                  lock: :until_and_while_executing

  def perform_with_error_handling(id)
    @order = Order.find(id)

    if order_invoiced_value.zero?
      create_comment("Order doesn't have values for invoice.")
      return
    end

    begin
      tax_service = Avalara::OrderTaxService.new(@order)
      invoice = tax_service.submit_invoice
      transaction_code = invoice.get_transaction_code

      if invoice.get_total == order_invoiced_value
        tax_service.confirm_invoice(transaction_code)
        create_comment("AvaTax: Order taxes invoiced. Transaction Code: #{transaction_code}")
      else
        error_message = "AvaTax: Order taxes could not invoice. Mismatch detected between Minibar ($#{order_invoiced_value}) and Avalara ($#{invoice.get_total}). Transaction Code: #{transaction_code}"
        create_comment(error_message)
      end
    rescue StandardError => e
      notify_sentry_and_log(e, "Error invoicing order #{e.message}", { tags: { order_id: @order.id } })
    end
  end

  private

  def order_invoiced_value
    # TODO: add the video service fee
    invoiced_value = @order.order_amount.service_fee_after_discounts.to_f.round(2)
    invoiced_value += @order.order_amount.membership_tax.to_f.round(2)
    invoiced_value += @order.order_amount.membership_price.to_f.round(2)
    invoiced_value
  end

  def create_comment(message)
    @order.comments.create({ note: message, posted_as: :minibar })
  end
end
