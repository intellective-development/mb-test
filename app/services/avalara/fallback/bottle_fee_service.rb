module Avalara
  module Fallback
    class BottleFeeService
      # Updated 04/31/2022 according to https://newsroom.tomra.com/bottle-bill-states/
      FEES = {
        "CA": 0.10,
        "CT": 0.05,
        "HI": 0.05,
        "IA": 0.05,
        "ME": 0.15,
        "MA": 0.05,
        "MI": 0.10,
        "NY": 0.05,
        "OR": 0.10,
        "VT": 0.15
      }.freeze

      def initialize(shipment, fallback_address = nil)
        @shipment = shipment
        @fallback_address = fallback_address
      end

      def get_bottle_fee(order_item)
        return 0.0 unless bottle_fee_applicable?(order_item)

        address = Avalara::Helpers.get_taxable_address(@shipment, @fallback_address)
        state_abbr = address&.state&.abbreviation&.upcase&.to_sym

        unit_fee = get_fee_amount(state_abbr)
        pack_size = order_item&.variant&.product&.container_count&.to_f || 1.0

        (unit_fee * order_item.quantity * pack_size).to_f.round_at(2)
      end

      private

      def bottle_fee_applicable?(order_item)
        container_type = order_item&.variant&.container_type&.downcase

        %w[bottle can].include?(container_type)
      end

      def get_fee_amount(state)
        state_fee = FEES[state]
        return state_fee unless state_fee.nil?

        0.0
      end
    end
  end
end
