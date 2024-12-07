class Order::AmountsWithoutDigitalShipments < Order::Amounts
  private

  def shipments
    super.reject(&:digital?)
  end
end
