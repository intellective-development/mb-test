class Variant
  module FacebookFeedSerializer
    extend ActiveSupport::Concern

    def as_facebook_feed_variant
      {
        availability: sold_out? ? 'out of stock' : 'in stock',
        brand: brand_name,
        condition: 'new',
        description: description || name,
        id: product_id,
        image_link: product_size_grouping.featured_image(:product),
        link: "#{DeepLink.url_base}/store/product/#{permalink}",
        price: price,
        title: name
      }
    end
  end
end
