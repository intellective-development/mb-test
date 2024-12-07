module Content
  class ProductBanner
    attr_reader :config, :options, :suppliers, :variant, :promotion

    # Options
    # =======
    # - `product_id` defines the specfic product which is to be featured.
    # - `product_grouping_id`, defines the product grouping to be be featured. This
    #   is used in cases where we don't care about featuring a specific size.
    # - `promotion_id` defines the promotion corresponding to the banner.
    def initialize(options, suppliers = nil)
      @options = options
      @suppliers = suppliers if suppliers.is_a?(Array)

      generate_config
    end

    def generate_config
      return unless variant && promotion

      @config = {
        product_grouping: variant.product_size_grouping.get_entity(nil, nil, suppliers.pluck(:id)),
        banner: ConsumerAPIV2::Entities::Banner.represent(promotion)
      }
    end

    private

    def suppliers
      @suppliers ||= Supplier.where(id: options[:supplier_ids])
    end

    def promotion
      @promotion = Promotion.active.at(Time.zone.now).find_by(id: options[:promotion_id])
    end

    def variant
      @variant ||= if options[:product_id]
                     Variant.active.available.where(supplier_id: suppliers.pluck(:id), product_id: options[:product_id]).first
                   else
                     Variant.active.available.joins(:product_size_grouping).where(supplier_id: suppliers.pluck(:id), product_groupings: { id: options[:product_grouping_id] }).first
                   end
    end
  end
end
