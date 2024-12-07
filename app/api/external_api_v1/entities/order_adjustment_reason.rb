# frozen_string_literal: true

class ExternalAPIV1
  module Entities
    class OrderAdjustmentReason < Grape::Entity
      expose :id
      expose :name
      expose :description
      expose :order_adjustment
      expose :active
      expose :cancel
      expose :reporting_type
    end
  end
end
