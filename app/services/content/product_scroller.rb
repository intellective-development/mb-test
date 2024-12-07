module Content
  class ProductScroller
    include SentryNotifiable

    attr_reader :config, :options, :suppliers, :variant, :user

    MIN_RESULT_COUNT = 1

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
      return unless options[:content_url]
      return unless suitable_for_user?
      return unless (options[:product_grouping_id] && options[:product_grouping_similarity_type] == 'brand' && results?) || (options[:product_grouping_id] && options[:product_grouping_similarity_type] != 'brand') || results?

      @config = {
        title: options[:title].presence,
        action_url: action_url,
        content_url: content_url
      }
    end

    private

    def suitable_for_user?
      # In cases where we are showing only content from previous orders, we want
      # to suppress for logged out and/or users with no orders.
      if options[:content_url].include?('only_previous=true')
        user && user.orders.finished.exists?
      else
        true
      end
    end

    def results?
      Rails.cache.fetch("content:product_scroller:#{content_url(only_path: true)}", expires_in: 24.hours) do
        @conn = Faraday.new(url: ENV['LAMBDA_API_URL'])

        response = @conn.get do |req|
          path = content_url(only_path: true)
          path += "&per_page=#{MIN_RESULT_COUNT}"
          req.url(path)
          Rails.logger.error("Getting product scroller data: #{ENV['LAMBDA_API_URL']}, path: #{path}")
          req.headers['Content-Type'] = 'application/json'
          req.headers['Authorization'] = options[:auth_header]
        end

        results = JSON.parse(response.body)
        count = results['product_groupings']&.count || 0
        Rails.logger.error("Product scroller result: #{count}")
        count >= MIN_RESULT_COUNT
      end
    rescue StandardError => e
      # In the event of a failure, we want to show the scroller vs hiding it.
      notify_sentry_and_log(e)
      true
    end

    def action_url
      if options[:action_url] && !options[:product_grouping_id]
        options[:platform] == 'web' ? options[:action_url] : DeepLink.add_url_base(options[:action_url])
      end
    end

    def suppliers
      @suppliers ||= Supplier.where(id: options[:supplier_ids])
    end

    def content_url(only_path: false)
      options[:product_grouping_id] ? related_product_url(only_path: only_path) : product_grouping_url(only_path: only_path)
    end

    def product_grouping_url(only_path: false)
      if only_path
        DeepLink.api_product_groupings_uri(options[:content_url], suppliers, options[:shipping_state])
      else
        DeepLink.api_product_groupings(options[:content_url], suppliers, options[:shipping_state])
      end
    end

    def related_product_url(only_path: false)
      query_hash = {
        product_grouping_id: options[:product_grouping_id],
        preferred_supplier_id: options[:preferred_supplier_id],
        count: options[:count] || 8,
        product_grouping_similarity_type: options[:product_grouping_similarity_type] || 'content'
      }
      if only_path
        DeepLink.api_related_products_uri(query_hash.to_query, suppliers, options[:shipping_state])
      else
        DeepLink.api_related_products(query_hash.to_query, suppliers, options[:shipping_state])
      end
    end
  end
end
