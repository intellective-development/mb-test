class ShippingSupplierService
  def initialize(shipping_state)
    @shipping_state = String(shipping_state).upcase
  end

  def call
    @suppliers = Supplier.active.joins(:delivery_zones, :supplier_type).where(delivery_zones: { type: 'DeliveryZoneState', value: @shipping_state, active: true }, supplier_types: { deferrable: true }, shipping_methods: { active: true })
  end
end
