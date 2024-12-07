class DynamicShippingService
  def initialize(shipment)
    @shipment = shipment
  end

  def shipping_fee
    return dynamic_shipping_config.heavy_fee if weight > DynamicShippingConfig::HEAVY_WEIGHT_THRESHOLD

    @shipping_fee ||= dynamic_shipping_config.apply_surcharge(ship_service_charge)
  end

  def weight
    @weight ||= WeightCalculator.new.weight_of_shipment(@shipment)
  end

  def distance
    log_and_raise_error "Order #{@shipment.order.number} without ship address" if @shipment.order.ship_address.nil?
    log_and_raise_error "Order #{@shipment.order.number} without supplier address" if @shipment.supplier.address.nil?

    @distance ||= @shipment.order.ship_address.distance_to(@shipment.supplier.address, :mi)
  end

  def ship_service_charge
    charge = FedexNetFreightCharge.calculate_fee(weight, distance)

    log_and_raise_error "Cannot calculate fee for #{weight}lbs for #{distance}mi" if charge.nil?

    charge
  end

  def dynamic_shipping_config
    @dynamic_shipping_config ||= DynamicShippingConfig.first_or_create!
  end

  def log_and_raise_error(message)
    Rails.logger.error message
    raise DynamicShippingError, message
  end
end
