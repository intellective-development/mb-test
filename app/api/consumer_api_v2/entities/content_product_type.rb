class ConsumerAPIV2::Entities::ContentProductType < Grape::Entity
  expose :id
  expose :name
  expose :target do |product_type|
    DeepLink::Web.product_type(product_type)
  end
  expose :type do |_product_type|
    'image'
  end
  expose :content do |product_type|
    product_type.banner_image(:default)
  end
  expose :impression_tracking_id do |product_type|
    "#{product_type.name}_placement__impression"
  end
  expose :click_tracking_id do |product_type|
    "#{product_type.name}_placement__impression"
  end

  # TODO: Convert the target url into universal deeplink format.
  # expose :target
  # expose :impression_tracking_id
  # expose :click_tracking_id
  expose :placement do |_p|
    options[:placement_name].to_s
  end
end
