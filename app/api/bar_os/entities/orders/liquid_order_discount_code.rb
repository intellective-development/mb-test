# frozen_string_literal: true

module BarOS
  module Entities
    module Orders
      # LiquidOrderDiscountCode
      class LiquidOrderDiscountCode < LiquidBase
        expose :code
        expose :amount, format_with: :float_string
        expose :type
      end
    end
  end
end
