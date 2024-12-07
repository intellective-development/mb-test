module Content
  class Product
    attr_reader :config, :options, :suppliers, :variant

    # Options
    # =======
    # - `product_id` defines the specfic product which is to be featured.
    # - `product_grouping_id`, defines the product grouping to be be featured. This
    #   is used in cases where we don't care about featuring a specific size.
    # - `description`, optional, defines content to be used instead of the
    #   description present on the product grouping.
    def initialize(options, suppliers = nil)
      @options = options
      @suppliers = suppliers if suppliers.is_a?(Array)

      generate_config
    end

    def generate_config
      return unless variant

      @config = {
        description: options[:description],
        display_variant_id: options[:product_id] ? variant.id : nil,
        product_grouping: variant.product_size_grouping.get_entity(nil, nil, suppliers.pluck(:id))
      }
    end

    private

    def suppliers
      @suppliers ||= Supplier.where(id: options[:supplier_ids])
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
