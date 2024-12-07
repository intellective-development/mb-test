module Content
  class NavigationCategory
    attr_reader :config, :options, :product_type_source, :icon_content_placement

    # Options
    # =======
    # - `supplier_ids` or suppliers passed as a parameter.
    # - `sources`, array of configurations for the links to be passed in and consumed
    # - `platform`, whether the content is being rendered for web or mobile
    # - `include_dropdown_section_id`, optional, boolean that suggests whether or not the dropdown_section_id key should be included in the response
    # - `icon_content_placement_name`, optional, the name of the content placement containing the nav icons

    def initialize(options)
      @options = options
      @product_type_source = Content::ProductTypeSource.new(options)

      if options[:icon_content_placement_name]
        @icon_content_placement = ContentPlacement
                                  .includes(:default_promotion, :promotions)
                                  .find_by(name: options[:icon_content_placement_name])
      end

      generate_config
    end

    def generate_config
      @config = {
        links: links_config
      }
    end

    private

    def links_config
      return [] unless options[:sources]

      options[:sources].flat_map do |source|
        case source['type']
        when 'static' # TODO: legacy, remove after transition to new nav
          source['content'].map(&:symbolize_keys)
        when 'tag'
          tag_config(source['content'], source['display_name'])
        when 'product_type'
          product_type_source.get_product_types.map do |pt|
            product_type_config(pt, !product_type_source.covered_types.include?(pt.name))
          end
        end
      end
    end

    def tag_config(tag_name, display_name)
      action_url = DeepLink::Web.tag(tag_name) if options[:platform] == 'web'
      dropdown_section_id = "dropdown_#{tag_name.parameterize}" if options[:include_dropdown_section_id]

      config = {
        name: display_name || tag_name.titleize,
        internal_name: tag_name.parameterize,
        action_url: action_url,
        icon_banner: icon_banner({ tag: tag_name }),
        dropdown_section_id: dropdown_section_id
      }.compact
    end

    def product_type_config(product_type, suppress_action_url = false)
      action_url =
        if suppress_action_url
          nil
        elsif options[:platform] == 'web'
          DeepLink::Web.product_type(product_type, [])
        else
          DeepLink.product_type(product_type)
        end

      dropdown_section_id = "dropdown_#{product_type.name.parameterize}" if options[:include_dropdown_section_id]

      {
        name: product_type.name.titleize,
        internal_name: product_type.name.parameterize,
        action_url: action_url,
        icon_banner: icon_banner({ type: product_type.id }),
        dropdown_section_id: dropdown_section_id
      }.compact
    end

    def icon_banner(matcher_options)
      return nil unless icon_content_placement

      promotion = icon_content_placement
                  .promotions
                  .active.at(Time.zone.now)
                  .for_supplier(options[:supplier_ids])
                  .select { |p| p.eligible?(matcher_options) }
                  .first

      # TODO: Consider a lite banner entity - just the image stuff, no tracking, url, etc
      ConsumerAPIV2::Entities::Banner.represent(promotion) if promotion
    end
  end
end
