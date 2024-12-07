class ConsumerAPIV2::Entities::Category < Grape::Entity
  expose :id
  expose :name
  expose :position
  expose :permalink
  expose :image_path do |category|
    category.image.photo.url(:category)
  rescue StandardError
    ''
  end
  expose :category_label do |category|
    category.name == 'wine' ? 'region' : 'brand'
  end
  expose :type_label do |category|
    category.name == 'case deals' ? '' : 'type'
  end
end
