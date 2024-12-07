class SupplierNotifier < BaseNotifier
  helper :customer_notifier

  def order_notification(notification_method_id, shipment_id, employee_id = nil)
    notification_method = Supplier::NotificationMethod.includes(:supplier).find(notification_method_id) if notification_method_id
    employee = Employee.find(employee_id) if employee_id

    @supplier    = notification_method&.supplier || employee&.supplier
    @email       = notification_method&.email || employee&.email

    return nil unless CustomValidators::Emails.email_validator.match?(@email)

    @shipment    = Shipment.includes(:address, order: %i[user order_items]).find(shipment_id)
    @address     = @shipment.address
    @order       = @shipment.order
    @user        = @shipment.order.user
    @order_items = @shipment.order_items
    @gift_order  = @order.gift?

    subject_line = format_subject("[Minibar] Order Placed - #{@order.number.upcase}")

    mail(to: @email, subject: subject_line, importance: 'High') do |format|
      format.html { render layout: 'email_ink' }
      format.text
    end
  end

  def supplier_braintree_daily_orders(supplier_id, date = nil)
    @supplier = Supplier.find(supplier_id)
    return nil unless @supplier&.braintree?
    return nil unless @supplier.emails.any?

    @day = Date.parse(date) unless date.nil?
    @day = Date.yesterday if @day.blank?

    starts_at         = @day.in_time_zone(@supplier.timezone).beginning_of_day
    ends_at           = @day.in_time_zone(@supplier.timezone).end_of_day
    supplier_totals   = MinibarReports::DailySupplier.new(supplier_id, starts_at, ends_at)

    @adjustments = OrderAdjustment.includes(:order)
                                  .joins(:shipment)
                                  .where('chargeables.created_at > ?', starts_at)
                                  .where('chargeables.created_at < ?', ends_at)
                                  .where(shipments: { supplier_id: @supplier.id })

    @order_count      = supplier_totals.total_orders
    @order_total      = supplier_totals.total_sales
    @orders           = supplier_totals.orders.sort_by { |e| e[:completed_at] }.to_a
    return nil if @orders.empty?

    subject_line = "Daily Summary for #{@supplier.name}, #{@day.strftime('%m/%d/%Y')}"
    mail(to: @supplier.emails, subject: format_subject(subject_line)) do |format|
      format.html { render layout: 'email_ink' }
    end
  end
end
