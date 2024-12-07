# frozen_string_literal: true

module BarOS
  module Entities
    module Orders
      # LiquidBase
      class LiquidBase < Grape::Entity
        format_with(:float) { |v| v && Float(v) }
        format_with(:force_string) { |v| v&.to_s }
        format_with(:float_string) { |v| v && Float(v).to_s }
        format_with(:timestamp) { |v| v&.to_datetime&.utc&.strftime('%FT%T.%LZ') }
      end
    end
  end
end
