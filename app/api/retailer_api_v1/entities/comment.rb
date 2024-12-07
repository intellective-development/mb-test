# frozen_string_literal: true

# Retailer comment entity
class RetailerAPIV1::Entities::Comment < Grape::Entity
  format_with(:iso_timestamp) { |dt| dt&.iso8601 }

  expose :posted_as, as: :postedAs
  expose :createdAt do |comment, options|
    comment.created_at&.in_time_zone(options[:supplier_timezone])&.iso8601
  end
  expose :note
  expose :author do
    expose :name do |comment|
      comment.user&.name
    end
    expose :email do |comment|
      comment.user&.email
    end
  end
  expose :file_url, as: :file
end
