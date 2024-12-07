class ConsumerAPIV2::Entities::Alternative < Grape::Entity
  expose :id do |alternative|
    alternative[:request_id]
  end
  expose :product, with: ProductGroupingVariantStoreView::Entity do |alternative|
    alternative[:variant]&.product_grouping_variant_store_view
  end
  expose :product_grouping do |alternative|
    view = alternative[:variant]&.product_grouping_variant_store_view&.grouping_view
    ProductGroupingStoreView::Entity.represent(view, exclude_variants: true)
  end
end
