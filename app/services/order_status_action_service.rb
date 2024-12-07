# This service generates tracking URLs based on shipping type.
class OrderStatusActionService
  attr_accessor :shipping_method, :shipment

  def initialize(shipment)
    @shipment        = shipment
    @shipping_method = shipment.shipping_method
  end

  def generate_url
    return nil unless shipping_method.trackable?

    case shipping_method.shipping_type
    when 'shipped'
      shipment_tracking_url
    when 'pickup'
      navigation_url(shipment.supplier)
    end
  end

  def self.navigation_url(supplier)
    return nil unless supplier.address

    "#{GOOGLE_MAPS_URL_BASE}#{URI.escape supplier.name},#{URI.escape supplier.address.full_street_address}"
  end

  private

  GOOGLE_MAPS_URL_BASE = 'https://www.google.com/maps/search/?api=1&query='.freeze

  def navigation_url(supplier)
    self.class.navigation_url(supplier)
  end

  def shipment_tracking_url
    shipment.tracking_number_url
  end
end
