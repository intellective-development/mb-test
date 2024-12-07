class ConsumerAPIV2::Entities::ProductGroupingGroupedBySupplier < Grape::Entity
  expose :supplier_id
  expose :product_groupings, with: ProductGroupingStoreView::Entity

  private

  def supplier_id
    object[0]
  end

  def product_groupings
    object[1]
  end
end
