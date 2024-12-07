# frozen_string_literal: true

class InternalAPIV1
  module Entities
    # InternalAPIV1::Entities::Supplier
    class ShippingMethod < Grape::Entity
      expose :shipping_type, as: :type
      expose :delivery_minimum, as: :minimum_delivery_expectation
      expose :maximum_delivery_expectation
    end
  end
end
