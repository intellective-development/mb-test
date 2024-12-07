class Shared::Entities::Tools::ToolIcon < Grape::Entity
  expose :id
  expose :image_url do |image|
    image&.file(:original)
  end
end
