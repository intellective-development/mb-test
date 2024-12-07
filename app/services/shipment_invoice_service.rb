class ShipmentInvoiceService
  def initialize(shipment)
    @shipment = shipment
  end

  def generate_invoice_html
    ActionController::Base.new.render_to_string(template: 'admin/fulfillment/shipments/pdf', locals: invoice_locals).to_str
  end

  def badges
    badge_list = []
    badge_list.push(type: 'gift', label: 'gift')                  if @shipment.order.gift?
    badge_list.push(type: 'new-customer', label: 'New Customer')  if @shipment.user.orders.finished.size < 2
    badge_list.push(type: 'scheduled', label: 'Scheduled')        if @shipment.scheduled_for.present?
    badge_list.push(type: 'vip', label: 'vip')                    if @shipment.order.vip?
    badge_list
  end

  def grouped_order_items
    @shipment.order_items.includes(:variant).group_by(&:variant)
  end

  private

  def invoice_locals
    locals = {
      badges: badges,
      order_items: grouped_order_items,
      order: @shipment.order,
      shipment: @shipment,
      storefront: @shipment.order.storefront,
      video_gift_message: @shipment.order.video_gift_message,
      order_tracking_qr_base64: Order::CreateTrackingQrCodeService.new(order_id: @shipment.order.id).call
    }
  end
end
