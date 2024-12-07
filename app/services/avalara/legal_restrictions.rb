module Avalara
  class LegalRestrictions
    def self.allows_alcohol_discounts?(state_abbr)
      !%(IN MO NJ).include?(state_abbr)
    end

    def self.allows_shipping_discounts?(state_abbr)
      !%(MO).include?(state_abbr)
    end
  end
end
