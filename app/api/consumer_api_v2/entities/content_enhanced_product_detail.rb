class ConsumerAPIV2::Entities::ContentEnhancedProductDetail < Grape::Entity
  expose :click_tracking_id
  expose :content
  expose :id
  expose :impression_tracking_id
  expose :placement
  expose :type

  private

  def type
    'json'
  end

  def placement_name
    String(options[:placement_name])
  end
end
