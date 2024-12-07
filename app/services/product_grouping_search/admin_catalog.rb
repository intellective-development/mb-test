class ProductGroupingSearch::AdminCatalog < ProductGroupingSearch::Base
  SEARCH_FIELDS = %i[name brand tags].freeze

  def initialize(params)
    @params = params.dup.freeze
    @supplier_ids = params[:supplier_ids].freeze

    super(@params[:query].presence || WILDCARD_QUERY)
  end

  # def search
  #   results = ProductSizeGrouping.search(@query, search_options)
  # end

  def search_options
    {
      where: get_filters,
      order: get_sort_order,
      per_page: 15,
      page: @params[:page] || 1,
      fields: SEARCH_FIELDS,
      debug: true,
      includes: [
        :images,
        :hierarchy_category,
        :hierarchy_type,
        :hierarchy_subtype,
        { brand: [:parent],
          products: [:active_variants] }
      ]
    }
  end

  def nested_matches
    []
  end

  private

  # SEARCH COMPONENTS
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
      state: { not: 'merged' }
    }
    filters[:product_states] = { in: @params[:state_filters] } if @params[:state_filters].present?
    or_clause_array = []
    if @params[:brand_ids].present?
      brand_ids = @params[:brand_ids]
      or_clause_array << [{ parent_brand_id: brand_ids }, { brand_id: brand_ids }]
    end

    if @params[:product_type_ids].present?
      or_clause_array << [
        { hierarchy_category: @params[:product_type_ids] },
        { hierarchy_type: @params[:product_type_ids] },
        { hierarchy_subtype: @params[:product_type_ids] }
      ]
    end

    filters[:skus] = @params[:sku] if @params[:sku].present?

    if @params[:has_image].present?
      or_clause_array << [
        has_image: @params[:has_image]
      ]
    end

    filters[:or] = or_clause_array if or_clause_array.any?
    filters
  end
end
