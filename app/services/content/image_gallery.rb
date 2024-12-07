module Content
  class ImageGallery
    attr_reader :config, :options, :content_placement

    # Options
    # =======
    # - `content_placement_name` - Corresponds to a name of a content placement
    #   which contains the banners.
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

      @config = {
        content: ConsumerAPIV2::Entities::Banner.represent(promotions)
      }
    end

    private

    def fetch_promotions
      promotions = content_placement.promotions.active.at(Time.zone.now).for_supplier(options[:supplier_ids]).select(&:eligible?).uniq
      promotions.push(content_placement.default_promotion) if promotions.empty? && content_placement.default_promotion
      promotions.sort_by(&:position)
    end
  end
end
