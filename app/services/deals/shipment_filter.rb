module Deals
  # == ShipmentFilter
  # Takes a shipment and a ActiveRecord::Relation and picks deals from the
  # relation that the shipment qualifies for. It does not validate the relationship
  # between the shipment and the deals in the relation. It is up the the AR::Relation
  # to provide only deals that relate to the shipment. Use Deals::QueryBuilder and any
  # relavent scopes to ensure ShipmentFilter is presented with appropriate deals.
  class ShipmentFilter
    extend Forwardable
    def_delegators :@restrictions, :allows_alcohol_discounts?, :allows_shipping_discounts?

    def initialize(shipment, relation)
      @shipment = shipment
      @relation = relation.respond_to?(:find_each) ? relation.find_each : Array(relation)
      @restrictions = LegalRestrictions.new(@shipment.address&.state_abbr_name || @shipment.order&.ship_address&.state_abbr_name)
    end

    def applicable_deals
      [
        first_of_type(FreeShipping),
        first_of_type(VolumeDiscount),
        all_of_type(TwoForOneDiscount),
        all_of_type(Percentage),
        all_of_type(MonetaryValue)
      ].compact.flatten
    end

    def first_of_type(type)
      qualified_deals.detect { |deal| deal.is_a?(type) }
    end

    def all_of_type(type)
      qualified_deals.select { |deal| deal.is_a?(type) }.force
    end

    def qualified_deals
      @relation
        .lazy
        .select { |deal| minimum_units_exceeded(deal) }
        .select { |deal| minimum_value_exceeded(deal) }
        .select { |deal| legally_compliant(deal) }
    end

    def legally_compliant(deal)
      return true if deal.is_a?(FreeShipping) && allows_shipping_discounts?

      @shipment.non_alcohol_item_count.positive? || allows_alcohol_discounts?
    end

    def minimum_units_exceeded(deal)
      case deal.type
      when 'VolumeDiscount'
        @shipment.case_eligible_item_count >= deal.minimum_units.to_i
      when 'TwoForOneDiscount'
        @shipment.two_for_one_eligible(deal)
      else
        @shipment.item_count >= deal.minimum_units.to_i
      end
    end

    def minimum_value_exceeded(deal)
      @shipment.sub_total >= deal.minimum_shipment_value.to_f
    end
  end
end
