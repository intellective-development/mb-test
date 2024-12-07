# frozen_string_literal: true

module BarOS
  module Entities
    module Orders
      # LiquidOrderShipmentPackage
      class LiquidOrderShipmentPackage < LiquidBase
        expose :id
        expose :carrier
        expose :tracking_number
        expose :tracking_url
        expose :package_custom_detail, with: BarOS::Entities::Orders::LiquidOrderShipmentPackageCustomDetail
      end
    end
  end
end
