class ConsumerAPIV2::Entities::ProductBundle < Grape::Entity
  expose :id
  expose :title
  expose :image do |product_bundle|
    product_bundle.images[0]
  end
  expose :component_product_data
  expose :external_id
end
