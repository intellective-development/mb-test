module Content
  class ProductTypeLinkList
    attr_reader :config, :options, :product_type_source

    # Options
    # =======
    # - `supplier_ids` or suppliers passed as a parameter.
    # - `product_type_id`, optional, denotes wether config should be generated
    #   for root-types or children of supplied product type.
    # - `platform`, whether its being rendered for web or mobile

    def initialize(options)
      @options = options
      @product_type_source = Content::ProductTypeSource.new(options)
      generate_config
    end

    def generate_config
      covered_types = product_type_source.covered_types
      content = product_type_source.get_product_types.map do |pt|
        covered_types.include?(pt.name) ? product_type_config(pt) : nil
      end.compact

      @config = {}
      @config[:content] = content
      @config[:shop_all_link] = shop_all_link_config if ancestors.any?
      @config[:title] = options[:title].presence || 'Categories'
    end

    private

    def product_type_config(product_type)
      action_url = @options[:platform] == 'web' ? DeepLink::Web.product_type(product_type, ancestors) : DeepLink.product_type(product_type)

      {
        name: product_type.name.titleize,
        internal_name: product_type.name.parameterize,
        action_url: action_url
      }
    end

    def shop_all_link_config
      parent, *parent_ancestors = ancestors
      action_url = @options[:platform] == 'web' ? DeepLink::Web.product_type(parent, parent_ancestors) : DeepLink.product_type(parent)

      {
        name: 'Shop All',
        internal_name: 'shop_all',
        action_url: action_url
      }
    end

    def ancestors
      @ancestors ||= if product_type_source.product_type_id.blank?
                       []
                     else
                       # This query is not ideal, as it's hitting the database twice (in addition to the database hit in ProductType::Source)
                       # Ultimately we may be better off dealing with a tree structure.
                       ProductType.active.find(product_type_source.product_type_id).sorted_self_and_ancestors
                     end
    end
  end
end
