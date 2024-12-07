class ConsumerAPIV2::Entities::VariantGroupedBySupplier < Grape::Entity
  expose :supplier_id
  expose :products, with: ApiViews::VariantStoreView::Entity

  private

  def supplier_id
    object[0]
  end

  def products
    object[1].map(&:variant_store_view)
  end
end
