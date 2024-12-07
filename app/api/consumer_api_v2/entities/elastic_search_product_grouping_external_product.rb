class ConsumerAPIV2::Entities::ElasticSearchProductGroupingExternalProduct < Grape::Entity
  expose :product_id, as: :id
  expose :permalink
  expose :min_price
  expose :max_price
  expose :container_type
  expose :volume
  expose :short_pack_size
  expose :short_volume
  expose :thumb_url
  expose :image_url do |product_view, options|
    # TODO: Would it be better to do this based on Doorkeeper Application ID?
    image_style =
      case options[:platform]
      when 'ios', 'iphone', 'ipad', 'ipod', 'android'
        :ios_product
      else
        :product
      end
    image_style == :ios_product ? product_view['image_url_mobile'] : product_view['image_url_web']
  end
end
