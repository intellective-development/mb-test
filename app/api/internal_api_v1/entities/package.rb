# frozen_string_literal: true

class InternalAPIV1
  module Entities
    # InternalAPIV1::Entities::Package
    class Package < Grape::Entity
      expose :carrier
      expose :tracking_number
      expose :tracking_url
      expose :state
      expose :label_url
      expose :expected_delivery_date
    end
  end
end
