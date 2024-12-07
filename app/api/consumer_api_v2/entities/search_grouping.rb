class ConsumerAPIV2::Entities::SearchGrouping < Grape::Entity
  expose :id
  expose :name
  # expose :variant_count do |product_size_grouping|
  #   product_size_grouping.products.inject {|sum, product| sum + product.variants.self_active.count}
  # end
  expose :products_count do |product_size_grouping|
    product_size_grouping.products.size
  end
  expose :state
  expose :master
end
