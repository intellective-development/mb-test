class Shared::Entities::Image < Grape::Entity
  expose :id
  expose :image_url, &:photo
end
