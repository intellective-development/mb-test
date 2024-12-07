class ConsumerAPIV2::Entities::Search::ProductType < Grape::Entity
  expose :description
  expose :permalink

  private

  def description
    object.sorted_self_and_ancestors.pluck(:name).compact.join(' - ')
  end

  def permalink
    DeepLink.product_type(object)
  end
end
