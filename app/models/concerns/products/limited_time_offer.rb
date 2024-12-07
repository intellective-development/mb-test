# frozen_string_literal: true

module Products
  # Concern with product limited time offer methods.
  module LimitedTimeOffer
    extend ActiveSupport::Concern

    included do
      const_set(:LTO_SOLD_QUANTITY_KEY, 'sold_quantity')
      const_set(:LTO_GLOBAL_LIMIT_KEY, 'global_limit')
    end

    def limited_time_offer_global_limit
      # Negative or zero value is consider without limit.
      limited_time_offer_data[Product::LTO_GLOBAL_LIMIT_KEY].to_i
    end

    def limited_time_offer_sold_quantity
      limited_time_offer_data[Product::LTO_SOLD_QUANTITY_KEY].to_i
    end

    def limited_time_offer_remain_quantity
      [limited_time_offer_global_limit - limited_time_offer_sold_quantity, 0].max
    end

    def clean_limited_time_offer_data
      # rubocop:disable Rails/SkipsModelValidations
      update_attribute(:limited_time_offer_data, {})
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
