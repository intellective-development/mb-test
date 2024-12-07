class ConsumerAPIV2::Entities::ContentProduct < Grape::Entity
  expose :type do |_p|
    'json'
  end

  expose :content do |product, options|
    ProductGroupingStoreView::Entity.represent(product[:content], exclude_variants: !options[:has_suppliers])
  end

  expose :id
  expose :impression_tracking_id
  expose :click_tracking_id
  expose :placement do |_p|
    options[:placement_name].to_s
  end
end
