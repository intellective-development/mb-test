class ConsumerAPIV2::Entities::ElasticSearchProductGroupingVariant < Grape::Entity
  include Shared::Helpers::ImageHelpers
  expose :variant_id, as: :id
  expose :price
  expose :original_price
  expose :in_stock
  expose :container_type
  expose :subgroup_id do |variant_view|
    variant_view['container_type']
  end
  expose :volume
  expose :short_pack_size
  expose :short_volume
  expose :thumb_url do |variant_view, options|
    image_with_fallback(variant_view['thumb_url'], options[:grouping_view].try(:[], 'thumb_url'))
  end
  expose :image_url do |variant_view, options|
    # TODO: Would it be better to do this based on Doorkeeper Application ID?
    image_style =
      case options[:platform]
      when 'ios', 'iphone', 'ipad', 'ipod', 'android'
        :ios_product
      else
        :product
      end
    if image_style == :ios_product
      image_with_fallback(variant_view['image_url_mobile'], options[:grouping_view].try(:[], 'image_url_mobile'))
    else
      image_with_fallback(variant_view['image_url_web'], options[:grouping_view].try(:[], 'image_url_web'))
    end
  end
  expose :permalink
  expose :supplier_id
  expose :product_id
  expose :deals, with: ConsumerAPIV2::Entities::ElasticSearchDeal
  expose :two_for_one
  expose :upc
  expose :custom_promo
  expose :sku
end
