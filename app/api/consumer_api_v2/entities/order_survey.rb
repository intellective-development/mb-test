class ConsumerAPIV2::Entities::OrderSurvey < Grape::Entity
  expose :token
  expose :date do |model|
    model.order.completed_at.iso8601
  end
  expose :number do |model|
    model.order.number
  end
  expose :items do |model|
    model.order.order_items.map(&:variant).uniq.count
  end
  expose :images do |model|
    model.order.order_items.map { |item| item.variant.featured_image(:small) if item&.variant }.uniq
  end
end
