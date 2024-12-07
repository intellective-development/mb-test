class Shipment::SendShipmentProcessedEventService
  def initialize(package:)
    raise ArgumentError.new, 'Package cannot be nil' if package.nil?

    @package = package
    @shipment = package.shipment
  end

  def call
    Shipment::SendShipmentProcessedEventWorker.perform_async(@package.id) if @shipment.customer_placement_back_order? || @shipment.customer_placement_pre_sale?
  end
end
