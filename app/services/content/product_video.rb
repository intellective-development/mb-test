module Content
  class ProductVideo
    attr_reader :config, :options

    # Options
    # =======
    # - `product_grouping_id`, the product_grouping whose video that will be passed back in config
    def initialize(options)
      @options = options
      @product_content = product_content

      generate_config
    end

    def generate_config
      @config = ConsumerAPIV2::Entities::ContentEnhancedProductDetail.represent(@product_content, options)
    end

    private

    def product_content
      raise MissingProductGroupingId if options[:product_grouping_id].blank?

      identifier = "video_content_#{options[:product_grouping_id]}"
      model = ProductSizeGrouping.includes(:product_content).find_by_identifier(options[:product_grouping_id])
      product_content = model&.product_content&.active ? model.product_content : false

      if product_content
        {
          id: identifier,
          impression_tracking_id: "#{identifier}__click",
          click_tracking_id: "#{identifier}__impression",
          content: {
            template: product_content.template,
            primary_background_color: product_content.primary_background_color,
            secondary_background_color: product_content.secondary_background_color,
            video: {
              mp4: product_content.video_mp4(:url),
              poster: product_content.video_poster(:url)
            }
          }
        }
      else
        {
          id: identifier,
          impression_tracking_id: false,
          click_tracking_id: false,
          content: false
        }
      end
    end

    class MissingProductGroupingId < ActionController::BadRequest
      def message
        'missing required param: product_grouping_id'
      end
    end
  end
end
