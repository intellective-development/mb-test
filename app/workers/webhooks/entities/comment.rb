# frozen_string_literal: true

module Webhooks
  module Entities
    # Webhooks::Entities::Comment
    class Comment < Grape::Entity
      format_with(:iso_timestamp) { |dt| dt&.utc&.iso8601 }

      expose :posted_as_string, as: :postedAs
      expose :created_at, as: :createdAt, format_with: :iso_timestamp
      expose :note
      expose :author do
        expose :name do |comment|
          comment.author&.name
        end
        expose :email do |comment|
          comment.author&.email
        end
      end
      expose :file

      def posted_as_string
        case object.posted_as
        when 0
          'Operations Team'
        when 1
          'Retailer'
        else
          ''
        end
      end
    end
  end
end
