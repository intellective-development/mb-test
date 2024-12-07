class SupplierAPIV2::Entities::Comment < Grape::Entity
  format_with(:iso_timestamp) { |dt| dt&.iso8601 }

  expose :id, :posted_as
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
