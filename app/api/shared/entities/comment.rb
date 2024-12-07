# frozen_string_literal: true

module Shared
  module Entities
    # comment shared entity
    class Comment < Grape::Entity
      format_with(:iso_timestamp) { |dt| dt&.iso8601 }

      expose :note
      expose :created_at, format_with: :iso_timestamp
    end
  end
end
