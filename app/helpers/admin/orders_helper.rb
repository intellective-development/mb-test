module Admin::OrdersHelper
  def format_exception_metadata(metadata)
    metadata ||= []
    table = '<table>'
    metadata.each do |k, v|
      key_string = I18n.t("exceptions.#{k}")
      table += "<tr><th>#{key_string}</th>"
      table += "<td>#{v}</td></tr>"
    end
    table += '</table>'
  end

  def shipping_charge(shipment)
    shipment&.shipment_shipping_charges.to_f.nonzero? ||
      shipment&.shipment_membership_shipping_discount.to_f.nonzero? ||
      shipment&.shipment_membership_delivery_discount.to_f.nonzero? ||
      0.0
  end
end
