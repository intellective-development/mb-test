module Content
  class ProductTypeScroller
    attr_reader :config, :options, :product_type_source

    ROOT_PRODUCT_TYPE_WHITELIST = %w[wine beer liquor mixers].freeze

    # Options
    # =======
    # - `supplier_ids` or suppliers passed as a parameter.
    # - `product_type_id`, optional, denotes wether config should be generated
    #   for root-types or children of supplied product type.
    def initialize(options, _suppliers = nil)
      @options = options

      @product_type_source = Content::ProductTypeSource.new(options)
      @config = {}
      generate_config
    end

    def generate_config
      config[:root] = product_type_source.root?
      config[:product_types] = product_types.map do |pt|
        if !pt.ios_menu_image
          nil
        elsif product_type_source.covered_types.include?(pt.name)
          product_type_config(pt)
        elsif product_type_source.root?
          product_type_config(pt, true)
        end
      end.compact

      config
    end

    private

    def product_types
      @product_types ||= product_type_source.get_product_types.includes(:ios_menu_image)
    end

    def product_type_config(product_type, suppress_action_url = false)
      {
        name: product_type.name.titleize,
        internal_name: product_type.name.parameterize,
        image_url: product_type.ios_menu_image.file.url,
        image_width: product_type.ios_menu_image.width,
        image_height: product_type.ios_menu_image.height,
        action_url: suppress_action_url ? nil : DeepLink.product_type(product_type)
      }
    end
  end
end
