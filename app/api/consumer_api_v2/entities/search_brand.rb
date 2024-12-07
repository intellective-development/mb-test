class ConsumerAPIV2::Entities::SearchBrand < Grape::Entity
  expose :id
  expose :name
  expose :description

  expose :groupings_count do |brand|
    brand.product_size_groupings.size
  end

  expose :sub_brands_count do |brand|
    brand.sub_brands.size
  end
end
