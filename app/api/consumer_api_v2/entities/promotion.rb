#
# THIS ENTITY IS DEPRICATED. CLIENTS, PLEASE TRANSITION TO USE
# CustomerAPIV2::Entities::Banner.
class ConsumerAPIV2::Entities::Promotion < Grape::Entity
  expose :display_name, as: :name
  expose :position
  expose :target, as: :url
  expose :image_path do |promotion|
    promotion.image(:original)
  end
  expose :image_height
  expose :image_width
  expose :ends_at do |promotion|
    promotion.ends_at.iso8601
  end
end
