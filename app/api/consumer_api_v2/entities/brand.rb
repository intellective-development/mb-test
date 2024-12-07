class ConsumerAPIV2::Entities::Brand < Grape::Entity
  expose :name
  expose :description
  expose :image_path do |brand|
    options[:platform] == 'web' ? brand.web_image(:original) : brand.mobile_image(:original)
  end
  expose :tag_list, as: :tags
end
