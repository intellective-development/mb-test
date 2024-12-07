module Content
  class TextCarousel
    attr_reader :config, :options, :content_placement

    # Options
    # =======
    # - `content_placement_name` - Corresponds to a name of a content placement
    #   which contains the banners.
    # - `hierarchy_category` - Corresponds to permalinks for categories, used for CLP banners.
    # - `tag` - Corresponds to tag names, used for CLP banners.
    # - `list_type` - Corresponds to specialty PLPs, used for CLP banners.
    # - `user_id`
    # - `platform`, whether the content is being rendered for web or mobile
    def initialize(options, suppliers = nil)
      @options = options
      @suppliers = suppliers if suppliers.is_a?(Array)
      @content_placement = ContentPlacement.includes(:default_promotion, :promotions)
                                           .find_by(name: options[:content_placement_name])

      generate_config
    end

    def generate_config
      return unless content_placement

      promotions = fetch_promotions
      return if promotions.empty?

      banner_options = { no_url_base: options[:platform] == 'web' }

      @config = {
        auto_rotate: true,
        interval: 5,
        content: ConsumerAPIV2::Entities::TextBanner.represent(promotions, banner_options)
      }
    end

    private

    def fetch_promotions
      matcher_options = {
        type: ProductType.select(:id).find_by(permalink: options[:hierarchy_category])&.id,
        tag: options[:tag],
        list_type: options[:list_type]
      }.compact

      promotions = content_placement.promotions.active.at(Time.zone.now).for_supplier(options[:supplier_ids]).select { |promotion| promotion.eligible?(matcher_options) }.uniq
      promotions.push(content_placement.default_promotion) if promotions.empty? && content_placement.default_promotion
      promotions.sort_by(&:position)
    end
  end
end
