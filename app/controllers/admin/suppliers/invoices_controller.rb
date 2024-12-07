class Admin::Suppliers::InvoicesController < Admin::BaseController
  MONTH_FILTER_FORMAT = '%Y-%m'.freeze

  def index
    @invoices = invoice_query.includes(:line_items, recipient: [:supplier])

    params[:month] = Date.today.last_month.strftime(MONTH_FILTER_FORMAT) if params[:month].blank? && params[:supplier_name_query].blank?

    if params[:month].present?
      start_date = Date.strptime(params[:month], MONTH_FILTER_FORMAT).in_time_zone
      @invoices = @invoices.where(period_start: start_date)
    end

    if (supplier_name_query = params[:supplier_name_query].present? && params[:supplier_name_query]&.downcase)
      @invoices = @invoices.joins(:recipient).where('lower(invoicing_recipients.description) like ?', "%#{supplier_name_query}%")
    end

    @invoices = @invoices.finalized if params[:only_finalized].present?

    @invoices = @invoices.order('suppliers.name', 'invoicing_ledger_items.period_start desc', 'invoicing_ledger_items.status', 'invoicing_ledger_items.created_at desc')

    respond_to do |format|
      format.html { @invoices = @invoices.page(pagination_page).per(25) }
      format.csv { send_data(generate_csv, filename: "#{business.name.downcase}-invoices-#{Date.today.strftime('%m/%d/%Y')}.csv") }
    end
  end

  def show
    @line_items = invoice.line_items.includes(:ledger_item).order(:tax_point)
    @potential_adjustments = invoice.find_pending_adjustments
  end

  def pdf
    @storefront = Storefront.find_by(name: business.name)
    @line_items = invoice.line_items.includes(:ledger_item).order(:tax_point)
  end

  def csv
    @line_items = invoice.line_items.includes(:ledger_item).order(:tax_point)

    send_data(
      CSV.generate(headers: true, col_sep: ',', force_quotes: true) do |csv|
        SupplierInvoiceService.generate_invoice_csv(csv, business, @line_items)
      end, type: Mime[:csv], filename: "#{business.name.downcase}-invoice-#{invoice.id}-#{invoice.period_start.strftime('%m/%d/%Y')}.csv"
    )
  end

  def new
    if params[:month].blank?
      flash[:alert] = 'Invoice missing start month'
    elsif params[:all].blank? && params[:recipient].blank?
      flash[:alert] = 'Invoice missing recipient'
    else
      suppliers = params[:all].present? ? Supplier.where(delegate_invoice_supplier_id: nil) : [Supplier.find(params[:recipient])]
      unless suppliers.first.delegate_invoice_supplier_id.nil?
        flash[:alert] = "The selected supplier '#{suppliers.first.name}' is delegating invoices to #{suppliers.first.delegate_invoice.name}."
        redirect_to action: :index
        return
      end
      suppliers.each do |supplier|
        generate_supplier_invoice(supplier, params[:month])
      end
      flash[:notice] = 'Invoicing started!'
    end
    redirect_to action: :index, business: params[:business]
  end

  def credits
    params['adjustments']&.each do |k, _v|
      adjustment = OrderAdjustment.includes(:order).find(k)
      invoice.add_adjustment_line(adjustment)
    end
    redirect_to action: :show, id: params[:id], business: params[:business]
  end

  def build
    invoice.delay.build!
    flash[:notice] = 'Invoice is being processed.'
    redirect_to action: :show, id: params[:id], business: params[:business]
  end

  def finalize
    invoice.delay.finalize!
    flash[:notice] = 'Invoice is being finalized.'
    redirect_to action: :show, id: params[:id], business: params[:business]
  end

  def void
    invoice.delay.void!
    flash[:notice] = 'Invoice will be voided.'
    redirect_to action: :show, id: params[:id], business: params[:business]
  end

  def pay
    invoice.pay!
    redirect_to action: :show, id: params[:id], business: params[:business]
  end

  def rerun
    generate_supplier_invoice(invoice.recipient.supplier, invoice.period_start.strftime(MONTH_FILTER_FORMAT), invoice.id)

    flash[:notice] = 'Invoicing will be generated again!'
    redirect_to action: :index, business: params[:business], month: params[:month], supplier_name_query: params[:supplier_name_query], only_finalized: params[:only_finalized]
  end

  private

  def business
    @business ||= Business.find_by(name: params[:business] || 'Minibar')
  end

  def business_id
    @business_id ||= business.id
  end

  def invoice_query
    @invoice_query ||= InvoicingLedgerItem.by_business(business_id)
  end

  def invoice
    @invoice ||= invoice_query.includes(business: :storefronts, line_items: :shipment_amount).find_by(uuid: params[:id])
  end

  def generate_csv
    headers = ['Recipient', 'Period', 'Status', 'Total', 'Invoiced Shipments']
    headers << 'PayPal Funds' unless business.default_business?

    CSV.generate(headers: true, col_sep: ',', force_quotes: true) do |csv|
      csv << headers
      @invoices.where(status: 'finalized').each do |invoice|
        period_start = invoice.period_start.utc.strftime('%m/%d/%Y')

        line = [invoice.recipient_name, period_start, invoice.status, invoice.total_amount || 0.00, invoice.invoiced_shipments || 0]
        line << (invoice.paypal_funds || 0.00) unless business.default_business?
        csv << line
      end
    end
  end

  def generate_supplier_invoice(supplier, month, invoice_id = nil)
    start_date = Date.strptime(month, MONTH_FILTER_FORMAT)
    GenerateSupplierInvoiceJob.perform_later(supplier.id, start_date, business_id, invoice_id) if supplier && !supplier.merchandise? && supplier.invoicing_enabled?
  end
end
