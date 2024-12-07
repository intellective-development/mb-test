# frozen_string_literal: true

class InternalAPIV1
  module Entities
    # InternalAPIV1::Entities::Comment
    class Comment < Grape::Entity
      format_with(:iso_timestamp) { |dt| dt&.iso8601 }

      expose :id
      expose :created_at do |comment, options|
        comment.created_at&.in_time_zone(options[:supplier_timezone])&.iso8601
      end
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
    end
  end
end
