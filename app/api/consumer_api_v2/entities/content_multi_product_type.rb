class ConsumerAPIV2::Entities::ContentMultiProductType < Grape::Entity
  expose :type do |_p|
    'multi_image'
  end
  expose :content do |p|
    p[:content].map { |promotion| ConsumerAPIV2::Entities::ContentProductType.new(promotion, placement_name: options[:placement_name]) }
  end
  expose :placement do |_p|
    options[:placement_name].to_s
  end
end
