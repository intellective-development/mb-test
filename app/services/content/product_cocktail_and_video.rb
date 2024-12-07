module Content
  class ProductCocktailAndVideo
    attr_reader :config, :options

    def initialize(options)
      @options = options
      @content_placement = ContentPlacement.includes(:promotions)
                                           .find_by(name: options[:content_placement_name])
      generate_config
    end

    def fetch_promotions(category_id, brand_id)
      match_search = ['brand', brand_id].join('=') unless brand_id.nil?
      filters = [
        { match_search: match_search },
        { type: category_id }
      ]
      promotions = @content_placement.promotions.active.at(Time.zone.now).select { |promotion| filters.any? { |filter| promotion.eligible?(filter) } }.uniq
      promotions.push(content_placement.default_promotion) if promotions.empty? && @content_placement.default_promotion
      promotions.sort_by(&:position)
    end

    def generate_config
      product_grouping_id = @options[:product_grouping_id]
      cocktails = []
      unless product_grouping_id.nil?
        product_grouping = ProductGrouping.find_by(id: @options[:product_grouping_id])
        unless product_grouping.nil?
          brand_id = product_grouping.brand_id
          category_id = product_grouping.hierarchy_category&.id
          filters = {
            brand_id: brand_id
          }
          promotions = []
          promotions = fetch_promotions(category_id, brand_id) unless @content_placement.nil?
          @all_matches = Cocktail.search '*', where: filters
          cocktails = @all_matches.map do |item|
            Shared::Entities::Cocktails::RelatedCocktail.represent item
          end
        end
      end

      @config = {
        video: Content::ProductVideo.new(@options).config,
        cocktails: cocktails,
        promotions: ConsumerAPIV2::Entities::Banner.represent(promotions)
      }
    end
  end
end
