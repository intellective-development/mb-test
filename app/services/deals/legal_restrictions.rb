module Deals
  class LegalRestrictions
    def initialize(state_abbreviation)
      @state_abbreviation = state_abbreviation
    end

    def disallows_alcohol_discounts?
      %w[TX].include?(@state_abbreviation)
    end

    def allows_alcohol_discounts?
      !disallows_alcohol_discounts?
    end

    def disallow_shipping_discounts?
      %w[MO].include?(@state_abbreviation)
    end

    def allows_shipping_discounts?
      !disallow_shipping_discounts?
    end
  end
end
