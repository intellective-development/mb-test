# frozen_string_literal: true

# SupplierInvoiceService
#
# Service for handling supplier invoices
class SupplierInvoiceService
  def self.generate_invoice_csv(csv, business, line_items)
    headers = [
      'Order Date',
      'Type',
      'Order Number',
      'Product Subtotal',
      'Tax',
      'Fees due Retailer',
      'Tip',
      'Delivery Fee',
      "#{business.name} Promo Codes",
      'Order Total'
    ]
    headers += ['PayPal Funds', 'Shipping Reimbursement'] unless business.default_business?
    headers += ["#{business.name} Gift Cards", "#{business.name} Marketing Fee", "Net Due to/from #{business.name}"]

    csv << headers
    line_items.each do |line_item|
      line = [line_item.tax_point.strftime('%m/%d/%Y')]
      if CustomerOrder::ADJUSTMENT_TYPES.include?(line_item.type)
        line << line_item.order_adjustment&.reason&.invoice_display_name || line_item.type
      else
        line << line_item.type
      end
      line << line_item.order_number
      case line_item.type
      when 'CustomerOrder'
        line << FormatAmountService.call(line_item.sub_total)
        line << FormatAmountService.call(line_item.taxed_amount)
        line << FormatAmountService.call(line_item.bottle_deposits)
        line << FormatAmountService.call(line_item.tip_amount)
        line << FormatAmountService.call(line_item.shipping_charges)
        line << FormatAmountService.call(-1 * line_item.promo_codes_discount)
        line << FormatAmountService.call(line_item.total_amount)
        unless business.default_business?
          line << FormatAmountService.call(line_item.paypal_funds)
          line << FormatAmountService.call(line_item.shipping_reimbursement_total)
        end
        line << FormatAmountService.call(line_item.gift_card_amount)
      else
        line += [nil, nil, nil, nil, nil, nil, nil]
        unless business.default_business?
          line << FormatAmountService.call(line_item.paypal_funds)
          line << nil # shipping_reimbursement_total
        end
        line << nil # gift_card_amount
      end
      line << FormatAmountService.call(line_item.marketing_fee)
      line << FormatAmountService.call(line_item.net_amount)

      csv << line
    end

    csv << totals(line_items.first.ledger_item, business) if line_items.present?

    csv
  end

  def self.totals(invoice, business)
    line = [nil, nil]
    line << 'Total'
    line << FormatAmountService.call(invoice.sub_total)
    line << FormatAmountService.call(invoice.taxed_amount)
    line << FormatAmountService.call(invoice.bottle_deposits)
    line << FormatAmountService.call(invoice.tip_amount)
    line << FormatAmountService.call(invoice.shipping_charges)
    line << FormatAmountService.call((invoice.promo_codes_discount || 0) * -1)
    line << FormatAmountService.call(invoice.items_total_amount)
    unless business.default_business?
      line << FormatAmountService.call(invoice.paypal_funds)
      line << FormatAmountService.call(invoice.shipping_reimbursement_total)
    end
    line << FormatAmountService.call(invoice.gift_card_amount)
    line << FormatAmountService.call(invoice.marketing_fee)
    line << FormatAmountService.call(invoice.net_amount)
  end
end
