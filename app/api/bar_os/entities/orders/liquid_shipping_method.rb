# frozen_string_literal: true

module BarOS
  module Entities
    module Orders
      # LiquidShippingMethod
      class LiquidShippingMethod < LiquidBase
        expose :id
        expose :active
        expose :delivery_minimum
        expose :delivery_fee
        expose :minimum_delivery_expectation, &:get_delivery_expectation
        expose :maximum_delivery_expectation
        expose :shipping_type
        expose :same_day_delivery
        expose :allows_scheduling
      end
    end
  end
end
