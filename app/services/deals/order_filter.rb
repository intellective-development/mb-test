module Deals
  # == OrderFilter
  # Takes a shipment and a ActiveRecord::Relation and picks deals from the
  # relation that the shipment qualifies for. It does not validate the relationship
  # between the shipment and the deals in the relation. It is up the the AR::Relation
  # to provide only deals that relate to the shipment. Use Deals::QueryBuilder and any
  # relavent scopes to ensure OrderFilter is presented with appropriate deals.
  class OrderFilter
    def initialize(order, relation)
      @order = order
      @relation = relation.respond_to?(:find_each) ? relation.find_each : Array(relation)
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
        .select { |deal| !deal.single_use || not_previously_used(deal) }
        .select { |deal| matches_nth_order(deal) }
        .select { |deal| minimum_units_exceeded(deal) }
        .select { |deal| minimum_value_exceeded(deal) }
    end

    def not_previously_used(deal)
      # I don't like doing this, but @shipment can't see order.user on a through when not persisted
      @order.user.applied_deals.where(deal_id: deal.id).none?
    end

    def matches_nth_order(deal)
      # I don't like doing this, but @shipment can't see order.user on a through when not persisted
      deal.applicable_order.zero? || @order.user.orders.finished.excluding_self(@order.id).count.next == deal.applicable_order.to_i
    end

    def minimum_units_exceeded(deal)
      @order.order_items_count >= deal.minimum_units.to_i
    end

    def minimum_value_exceeded(deal)
      @order.order_items_total >= deal.minimum_shipment_value.to_f
    end
  end
end
