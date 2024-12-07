# frozen_string_literal: true

module BarOS
  module Entities
    module Orders
      # LiquidOrderAdjustment
      class LiquidOrderAdjustment < LiquidBase
        expose :braintree
        expose :credit
        expose :description
        expose :amount, format_with: :float_string
        expose :processed
        expose :financial
        expose :taxes
      end
    end
  end
end
