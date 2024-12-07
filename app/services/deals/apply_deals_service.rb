module Deals
  class ApplyDealsService
    def initialize(order)
      @order = order
      restrictions = LegalRestrictions.new(@order.ship_address&.state_abbr_name || @order.promo_address&.fetch('state'))
      @value_calculator = ValueCalculator.new(restrictions, order_items: @order.shipments.flat_map(&:order_items))
      @applicable_deals = Set.new
    end

    def call
      return if query_params.empty?

      deals_relation = Deals::QueryBuilder.new(query_params).call

      reserve_and_apply_deals(deals_relation) if deals_relation.any?
    end

    def query_params
      @query_params ||= @order.shipments.each_with_object(QueryParamsBuilder.new) do |shipment, struct|
        struct.regions    << shipment.supplier&.region_id if shipment.supplier&.region
        struct.states     << shipment.supplier&.address&.state_id if shipment.supplier&.address
        struct.suppliers  << shipment.supplier_id if shipment.supplier
        struct.brands.merge shipment.order_items.flat_map { |item| Brand.parents_for(item.product_size_grouping&.brand_id).pluck(:id) }
      end.to_query
    end

    def reserve_and_apply_deals(relation)
      requested_deals = Deals::OrderFilter.new(@order, relation).applicable_deals

      apply_deals(applied_reservations(requested_deals.map(&:id)) + new_reservations(requested_deals), requested_deals)
    end

    def applied_reservations(requested_deal_ids)
      @order.applied_deals.where(deal_id: requested_deal_ids).map do |applied|
        DealGateway::Reservation.new(deal_id: applied.deal_id, reservation_id: applied.reservation_id)
      end
    end

    def new_reservations(requested_deals)
      existing_reservations = ->(applied_ids, deal) { applied_ids.include?(deal.id) }.curry[@order.applied_deals.pluck(:deal_id)]
      get_reservations requested_deals.reject(&existing_reservations)
    end

    def get_reservations(deals)
      return [] if deals.empty?

      reservation_params = ->(deal) { Hash[order_id: @order.id, deal_id: deal.id] }

      reservation_gateway = Deals::DealGateway::Reservations.new(deals: deals.map(&reservation_params))
      reservation_gateway.call
      reservation_gateway.successful
    end

    # TODO: We should stop reserving deals when the Shipment#deals_amount exceeds Shipment#sub_total
    # TODO: We should split monetary values proportionately across shipments
    def apply_deals(reservations, requested_deals)
      reservation_cache = Reservations.new(reservations, requested_deals)

      @order.shipments.each { |shipment| shipment.applied_deals_attributes = applied_deals_attributes(shipment, reservation_cache) }
    end

    def applied_deals_attributes(shipment, reservations)
      picker = ShipmentFilter.new(shipment, reservations.deals)

      applied_deal_attributes = picker.applicable_deals.uniq { |ad| [ad.type, ad.amount] }.map do |deal, _attributes|
        applied_deal_attributes(shipment, deal, reservations[deal.id])
      end

      shipment.applied_deals.each_with_object(applied_deal_attributes) do |applied_deal, deletions|
        deletions << Hash[id: applied_deal.id, _destroy: '1'] unless reservations.key?(applied_deal.deal_id) && picker.applicable_deals.any?
      end
    end

    def applied_deal_attributes(shipment, deal, reservation)
      applied_deal_attributes = {
        reservation_id: reservation.reservation_id,
        deal_id: deal.id,
        deal_type: deal.type,
        value: deal_value_for(shipment, deal),
        title: Deal::Presenter.new(deal).short_title,
        sponsor: deal.sponsor,
        sponsor_name: deal.sponsor_name
      }

      applied_deal = shipment.applied_deals.find_by(deal_id: deal.id)
      applied_deal_attributes[:id] = applied_deal.id if applied_deal

      applied_deal_attributes
    end

    def deal_value_for(shipment, deal)
      @value_calculator.call(shipment, deal)
    end

    QueryParamsBuilder = Struct.new(:regions, :states, :suppliers, :brands) do
      def to_query
        each_pair.with_object({}) { |(key, set), hash| hash[key] = Array(set) unless set.empty? }
      end

      def initialize
        super(*Array.new(size) { Set.new })
      end
    end
  end

  class Reservations < Hash
    attr_reader :deals

    def initialize(reservations, deals)
      reservations.each_with_object(self) { |reservation, hash| hash[reservation.deal_id] = reservation }
      @deals = deals.select { |deal| key?(deal.id) }
      super(nil)
    end
  end
end
