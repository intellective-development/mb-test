# frozen_string_literal: true

module BarOS
  module Entities
    module Orders
      # LiquidOrderShipmentTrackingDetail
      class LiquidOrderShipmentTrackingDetail < LiquidBase
        expose :id
        expose :carrier
        expose :reference
        expose :tracking_number_url, as: :tracking_url
      end
    end
  end
end
