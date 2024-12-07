# frozen_string_literal: true

class ConsumerAPIV2::Entities::StorefrontFont < Grape::Entity
  expose :id
  expose :name do |object|
    object.name.parameterize
  end
  expose :font_family, &:name
  expose :font_type
  expose :file_url do |font|
    font.font_file&.url
  end
end
