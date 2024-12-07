module Deals
  class PresentableDealPicker
    extend Forwardable
    def_delegators :@restrictions, :allows_alcohol_discounts?, :allows_shipping_discounts?

    def initialize(relation, is_alcohol:, state_abbreviation:)
      @relation = relation
      @is_alcohol = is_alcohol
      @restrictions = LegalRestrictions.new(state_abbreviation)
    end

    def first_of_type(type)
      qualified_deals.detect { |deal| deal.is_a?(type) }
    end

    def all_of_type(type)
      qualified_deals.select { |deal| deal.is_a?(type) }
    end

    def qualified_deals
      @qualified_deals ||=
        @relation
        .find_each
        .select { |deal| legally_compliant(deal) }
    end

    def legally_compliant(_deal)
      allows_alcohol_discounts? || !@is_alcohol
    end
  end
end
