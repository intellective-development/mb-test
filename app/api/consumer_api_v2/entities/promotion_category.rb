class ConsumerAPIV2::Entities::PromotionCategory < Grape::Entity
  expose :display_name, as: :name
  expose :position
  expose :target, as: :url
  expose :ends_at do |promotion|
    promotion.ends_at.iso8601
  end
end
