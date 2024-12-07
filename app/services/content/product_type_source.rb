module Content
  class ProductTypeSource
    attr_reader :options, :product_type_id, :supplier_ids

    ROOT_PRODUCT_TYPE_WHITELIST = ['wine', 'beer', 'liquor', 'mixers', 'snacks & more'].freeze

    # Options
    # =======
    # - `supplier_ids` or suppliers passed as a parameter.
    # - `product_type_id`, optional, denotes whether config should be generated
    #   for root-types or children of supplied product type.
    def initialize(options)
      @product_type_id = options[:product_type_id] || options[:hierarchy_category]
      @supplier_ids = options[:supplier_ids]
    end

    def get_product_types
      root? ? root_product_types : child_product_types
    end

    def root?
      product_type_id.blank?
    end

    def suppliers
      @suppliers ||= Supplier.active.includes(:profile).where(id: supplier_ids)
    end

    def covered_types
      product_types_names = suppliers.flat_map { |s| ProductType.order(:position).where(id: s.profile.product_type_ids).map(&:name) }
      @covered_types ||= product_types_names.uniq
    end

    def root_product_types
      ProductType.root
                 .active
                 .where(name: ROOT_PRODUCT_TYPE_WHITELIST)
                 .order(:position)
    end

    def child_product_types
      ProductType.find(product_type_id)
                 .children
                 .active
                 .order(:position)
    end
  end
end
