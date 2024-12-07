module Admin::InvoiceHelper
  def format_decimal(value, negative = false)
    format("#{'-' if negative}$%.2f", value || 0)
  end
end
