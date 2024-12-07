module Admin::ShipmentHelper
  def pre_sale_shipment_suppliers_eligible_for_switching_dropdown_items(shipment)
    Supplier.eligible_for_pre_sale_shipment(shipment).map { |s| [s.name, s.id] }
  end
end
