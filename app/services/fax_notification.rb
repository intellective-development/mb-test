class FaxNotification
  # TODO: Once we have transitioned fully to notification_methods, the send method can be renoved and this one takes its place
  def self.notify(notification_method, shipment)
    result = Phaxio.send_fax(
      to: notification_method.phone_number,
      string_data: ShipmentInvoiceService.new(shipment).generate_invoice_html,
      string_data_type: 'html',
      'tag[order_id]': shipment.order_number,
      'tag[supplier]': shipment.supplier.name
    )

    if result['success']
      FaxStatusWorker.perform_in(5.minutes, result['faxId'], shipment.supplier.id, shipment.id)
    else
      raise Minibar::FaxError.new(shipment.id, result.body)
    end
  end

  def self.send(supplier, shipment)
    result = Phaxio.send_fax(
      to: supplier.get_setting(:notify_fax),
      string_data: ShipmentInvoiceService.new(shipment).generate_invoice_html,
      string_data_type: 'html',
      'tag[order_id]': shipment.order_number,
      'tag[supplier]': shipment.supplier.name
    )

    if result['success']
      FaxStatusWorker.perform_in(5.minutes, result['faxId'], supplier.id, shipment.id)
    else
      raise Minibar::FaxError.new(shipment.id, result.body)
    end
  end

  def self.sent?(id)
    result = Phaxio.get_fax_status(id: id)
    result && result['data'] ? result['data']['status'] == 'success' : false
  end
end
