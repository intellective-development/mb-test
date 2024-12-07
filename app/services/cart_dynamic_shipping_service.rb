# frozen_string_literal: true

# This service is used to calculate shipping fee for a given cart
class CartDynamicShippingService
  def initialize(cart_items, supplier, address)
    @cart_items = cart_items
    @supplier = supplier
    @address = address
  end

  def shipping_fee
    return dynamic_shipping_config.heavy_fee if weight > DynamicShippingConfig::HEAVY_WEIGHT_THRESHOLD

    @shipping_fee ||= dynamic_shipping_config.apply_surcharge(ship_service_charge)
  end

  def weight
    @weight ||= WeightCalculator.new.weight_of_cart_items(@cart_items)
  end

  def distance
    @distance ||= @address.distance_to(@supplier.address, :mi)
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
