# frozen_string_literal: true

class ExternalAPIV1
  module Entities
    # ExternalAPIV1::Entities::OrderAdjustment
    class OrderAdjustment < Grape::Entity
      format_with(:price_formatter) { |value| value&.to_f&.round_at(2) }

      expose :id
      expose :financial
      expose :credit
      expose :description
      expose :amount, format_with: :price_formatter
      expose :reason, with: ExternalAPIV1::Entities::OrderAdjustmentReason
    end
  end
end
