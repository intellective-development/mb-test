class ProductGroupingSearch::AdminCatalogv2 < ProductGroupingSearch::Filters
  SEARCH_FIELDS = %i[name brand tags].freeze
  NESTED_PROPS = %w[supplier_id in_stock sku mechant_sku].freeze
  PROPS_LIST = %w[product_states product_ids brand_id skus parent_brand_id hierarchy_category hierarchy_type hierarchy_subtype has_image mechant_sku has_active_pre_sale limited_time_offer].concat(NESTED_PROPS)

  def initialize(params)
    @params = params.dup
    @supplier_ids = params[:supplier_ids].freeze

    super(@params[:query].presence || WILDCARD_QUERY)
  end

  # Implemented abstract method
  def search_options
    {
      where: get_filters,
      order: get_sort_order,
      per_page: 15,
      page: @params[:page] || 1,
      fields: SEARCH_FIELDS
    }
  end

  # Override parent's whitelist of filters for nested Variants
  def get_nested_props
    NESTED_PROPS
  end

  # Override parent's whitelist of filters for ProductSizeGroupings
  def get_props_list
    PROPS_LIST
  end

  private

  # SEARCH COMPONENTS
  def get_nested_terms(_terms_to_add, _for_facet)
    []
  end

  def get_sort_order
    search_order = []
    if @params[:sort].present?
      sort = @params[:sort]
      sort_direction = @params[:sort_direction].presence || (sort == 'name_downcase' ? :asc : :desc)
    elsif @params[:query].present? && @params[:query] != '*'
      # default sort by relevance when matching a query
      sort = :_score
      sort_direction = :desc
    else
      # default sort by name when nothing else
      sort = :name_downcase
      sort_direction = :asc
    end
    search_order << { sort => sort_direction }
    search_order
  end

  def get_filters
    filters = {
      state: { not: 'merged' } # Only here to initialize a query in case no filters are requested
    }

    filters[:product_states]         = @params[:state_filters]      if @params[:state_filters].present?
    filters[:has_image]              = @params[:has_image]          if @params[:has_image].present?
    filters[:brand_id]               = @params[:brand_ids]          if @params[:brand_ids].present? # will always include if passed any value, to handle invalid
    filters[:skus]                   = @params[:sku]                if @params[:sku].present?
    filters[:available_supplier_ids] = @supplier_ids                if @supplier_ids.present?
    filters[:merchant_skus]          = @params[:mechant_sku]        if @params[:mechant_sku].present?
    filters[:id]                     = { in: @params[:product_grouping_id].to_i } if @params[:product_grouping_id].present?
    filters[:product_ids]            = @params[:product_id].to_i if @params[:product_id].present?

    filters[:has_active_pre_sale]    = true                         if @params[:pre_sale_lto_filter] == 'has_active_pre_sale'
    filters[:limited_time_offer]     = true                         if @params[:pre_sale_lto_filter] == 'limited_time_offer'

    # Stick to the PLP behavior: if types of different depth, only deepest ones are returned. Could be fixed by an 'OR' clause when accepted by parent class.
    if @params[:product_type_ids].present?
      (hierarchy_categories, hierarchy_types, hierarchy_subtypes) = hierarchize_product_types(@params[:product_type_ids])
      filters[:hierarchy_category] = hierarchy_categories          if hierarchy_categories.any?
      filters[:hierarchy_type]     = hierarchy_types               if hierarchy_types.any?
      filters[:hierarchy_subtype]  = hierarchy_subtypes            if hierarchy_subtypes.any?
    end

    filters
  end

  def hierarchize_product_types(product_type_ids)
    categories = Set.new
    types = Set.new
    subtypes = Set.new

    product_type_ids.map { |id| hierarchize_product_type(id) }.each do |(category, type, subtype)|
      categories << category
      types << type
      subtypes << subtype
    end

    # Remove 'nil' values because index does not
    [categories.to_a.compact, types.to_a.compact, subtypes.to_a.compact]
  end

  def hierarchize_product_type(product_type_id)
    # Transforms an arbitrary product type into a hierarchized [category, type, subtype]
    product_type = ProductType.find_by(id: product_type_id)
    return [product_type&.id, nil, nil]                                           if product_type&.parent.blank?
    return [product_type&.parent&.id, product_type&.id, nil]                      if product_type&.parent&.parent.blank?

    [product_type&.parent&.parent&.id, product_type&.parent&.id, product_type&.id]
  end
end
