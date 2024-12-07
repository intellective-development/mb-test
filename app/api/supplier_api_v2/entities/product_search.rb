class SupplierAPIV2::Entities::ProductSearch < Grape::Entity
  expose :id
  expose :name do |product|
    product.product_size_grouping&.name || product.name
  end
  expose :item_volume
  expose :category, safe: true do |product|
    product.product_type&.ancestry_path&.join(' | ')
  end
  expose :quality_score
  expose :variant_count do |product|
    product.variants.self_active.count
  end
  expose :merged_count do |product|
    product.destination_merges.count
  end
  expose :state
end
