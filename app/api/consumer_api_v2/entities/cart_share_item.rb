class ConsumerAPIV2::Entities::CartShareItem < Grape::Entity
  format_with(:float, &:to_f)

  expose :quantity
  expose :product, with: ProductGroupingVariantStoreView::Entity, &:product_grouping_variant_store_view
  expose :product_grouping do |item|
    view = item.product_grouping_variant_store_view&.grouping_view
    ProductGroupingStoreView::Entity.represent(view, exclude_variants: true)
  end
end
