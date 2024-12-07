class ConsumerAPIV2::Entities::ContentSearchSuggestionsContent < Grape::Entity
  expose :product_groupings, with: ProductGroupingStoreView::Entity
  expose :supplier
  expose :total_results

  def supplier
    ConsumerAPIV2::Entities::SupplierProfile.represent(object[:supplier], shipping_methods: options[:shipping_methods])
  end
end

class ConsumerAPIV2::Entities::ContentSearchSuggestions < Grape::Entity
  expose :type do |_p|
    'json'
  end
  expose :content
  expose :impression_tracking_id
  expose :click_tracking_id
  expose :placement do |_p|
    options[:placement_name].to_s
  end

  def content
    ConsumerAPIV2::Entities::ContentSearchSuggestionsContent.represent(object[:content], shipping_methods: object[:_shipping_methods])
  end
end
