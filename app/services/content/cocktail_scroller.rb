module Content
  class CocktailScroller
    attr_reader :config, :options, :variant, :user

    MIN_RESULT_COUNT = 3

    # Options
    # =======
    # - `title`, optional, the title displayed with the scroller.
    # - `action_url`, optional, usually a CLP/PLP URL which deep links to
    #   the full product collection. Should be provided without base URL and with
    #   leading `/`
    # - `content_url`, the API URL which populates this collection. Should be provided
    #   as querystring only.
    # - `product_grouping_id`, optional, when present rather than using the content
    #   url attribute, we will find related products.
    def initialize(options, suppliers = nil)
      @options   = options
      @suppliers = suppliers if suppliers.is_a?(Array)
      @user      = User.find_by(id: options[:user_id])

      generate_config
    end

    def generate_config
      @config = {
        title: options[:title].presence,
        action_url: action_url,
        content_url: content_url,
        action_name: options[:action_name].presence,
        debug_layout: options[:debug_layout].presence
      }
    end

    private

    def action_url
      if options[:action_url] && !options[:product_grouping_id]
        options[:platform] == 'web' ? options[:action_url] : DeepLink.add_url_base(options[:action_url])
      end
    end

    def suppliers
      @suppliers ||= Supplier.where(id: options[:supplier_ids])
    end

    def content_url
      DeepLink.api_cocktails(options[:content_url])
    end

    def related_product_url
      query_hash = {
        product_grouping_id: options[:product_grouping_id],
        count: options[:count] || 8,
        product_grouping_similarity_type: options[:product_grouping_similarity_type] || 'content'
      }
      DeepLink.api_related_products(query_hash.to_query, suppliers, options[:shipping_state])
    end
  end
end
