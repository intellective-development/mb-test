module Geo
  class UpdateShippingStatesService
    attr_reader :shipping_method

    # TODO: Add a wisper event to trigger product catalog updates for VS products?=.

    def initialize(shipping_method, states)
      @shipping_method = shipping_method
      @states = states
      @delivery_zones = shipping_method.delivery_zones.states
    end

    def call
      deactivate_delivery_zones
      create_or_activate_delivery_zones
    end

    private

    def create_or_activate_delivery_zones
      @states.each do |state|
        existing_delivery_zone = @delivery_zones.find_by(value: state)
        if existing_delivery_zone
          existing_delivery_zone.update(active: true)
        else
          @shipping_method.delivery_zones.create(type: 'DeliveryZoneState', active: true, value: state)
        end
      end
    end

    def deactivate_delivery_zones
      delivery_zones_query = @delivery_zones.active.where.not(value: @states)
      delivery_zones_query.update_all(active: false)
    end
  end
end
