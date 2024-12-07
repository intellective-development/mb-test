#
# This is an opinionated wrapper around our variant search.
# The purpose is to have a consistent interface powering
# our store's navigation (including search).
class VariantSearchService
  attr_reader :results, :params, :filters, :aggs

  BEER_VOLUME_BLACKLIST = ['single'].freeze
  WINE_VOLUME_BLACKLIST = %w[50ml 187ml 200ml 300ml].freeze

  VOLUME_BLACKLISTED_BEER_SUPPLIER_ID = ENV['BEER_VOLUME_BLACKLIST_SUPPLIER_ID'] # 110 Village Farm
  VOLUME_BLACKLISTED_WINE_SUPPLIER_ID = ENV['WINE_VOLUME_BLACKLIST_SUPPLIER_ID'] # 9 East Houston

  def initialize(params)
    raise 'failed to instantiate VariantSearchService: missing params' if params.blank?
    raise 'failed to instantiate VariantSearchService: missing supplier_ids in params' if params[:supplier_ids].blank?

    @params = params.dup
    @supplier_ids = params[:supplier_ids].dup
  end

  def search
    set_sort_order
    set_filters_and_aggs
    set_boost

    @results = Variant.search(@params[:query],
                              includes: [:variant_store_view],
                              where: @filters,
                              routing: @supplier_ids,
                              aggs: @aggs,
                              order: @search_order,
                              boost_by: @boost,
                              per_page: @params[:per_page] || 20,
                              page: @params[:page] || 1,
                              fields: ['hierarchy^100', 'name^75', 'keywords^50', 'brand^30', 'country', 'region', 'appellation'])
    @results
  end

  def get_views
    @results&.map(&:variant_store_view)
  end

  private

  # SEARCH COMPONENTS
  def set_sort_order
    @search_order = []
    if @params[:query].present? && params[:query] != '*'
      sort = @params[:sort].presence || :_score
      sort_direction = @params[:sort_direction].presence || :desc
    else
      sort = @params[:sort].presence || :name
      sort_direction = @params[:sort_direction].presence || :asc
    end

    if [:name, 'name'].include?(sort)
      @search_order << { featured: :desc }
      sort = :name_downcase # we need to do this because Elastic Search defaults to case sensitive ordering
    end
    @search_order << { sort => sort_direction } # default sort to relevant
  end

  def set_boost
    @boost = @params[:query] != '*' ? [:popularity_60day] : []
  end

  def set_filters_and_aggs
    # defaults
    @filters = {
      active: true,
      in_stock: true,
      supplier_id: @supplier_ids
    }
    @aggs = {}
    facet_list = params[:facet_list] || []

    has_legacy_type_filter = @params[:type].present? && !ProductType.find(@params[:type]).root?

    # primary filters
    @filters[:ancestor_ids] = @params[:type] if @params[:type].present?
    @filters[:tags] = @params[:tag]          if @params[:tag].present?
    @filters[:brand_id] = filter_brand_ids   if @params[:brand].present? # will always include if passed any value, to handle invalid
    @filters[:product_id] = @params[:product_ids]                if @params[:product_ids].present?
    @filters[:hierarchy_category] = @params[:hierarchy_category] if @params[:hierarchy_category].present?
    @filters[:hierarchy_type] = @params[:hierarchy_type]         if @params[:hierarchy_type].present?
    @filters[:hierarchy_subtype] = @params[:hierarchy_subtype]   if @params[:hierarchy_subtype].present?
    # primary facets, independent of second teir filters, their filters, and their descendents
    @aggs[:hierarchy_type] = { where: @filters.except(:hierarchy_type, :hierarchy_subtype) } if facet_list.include?('hierarchy_type')
    @aggs[:hierarchy_subtype] = { where: @filters.except(:hierarchy_subtype) } if facet_list.include?('hierarchy_subtype') && (@params[:hierarchy_type] || has_legacy_type_filter)
    ## merge in brand here?

    # second teir filters
    @filters[:price] = filter_price_range    if @params[:price].present?
    @filters[:country] = @params[:country]   if @params[:country].present?
    @filters[:search_volume] = filter_volume if filter_volume
    # second teir facets, independent only of their respective filters
    @aggs[:price] = { ranges: facet_price_ranges, where: @filters.except(:price) } if facet_list.include?('price')
    @aggs[:country] = { where: @filters.except(:country) } if facet_list.include?('country')
    @aggs[:search_volume] = { where: @filters.except(:search_volume) } if facet_list.include?('search_volume')
    # TODO: We get better perf if we only specify fields for

    @filters.merge!(searchable: true) if @params[:query] != '*' # If we are searching only show searchable products.
  end

  ## FILTER AND FACET HELPERS
  def filter_volume
    if @params[:search_volume].present?
      @params[:search_volume]
    # This is for our beta testing.
    elsif @supplier_ids.include?(VOLUME_BLACKLISTED_BEER_SUPPLIER_ID.to_s) && @supplier_ids.include?(VOLUME_BLACKLISTED_WINE_SUPPLIER_ID.to_s)
      { not: WINE_VOLUME_BLACKLIST + BEER_VOLUME_BLACKLIST }
    elsif @supplier_ids.include?(VOLUME_BLACKLISTED_BEER_SUPPLIER_ID.to_s)
      { not: BEER_VOLUME_BLACKLIST }
    elsif @supplier_ids.include?(VOLUME_BLACKLISTED_WINE_SUPPLIER_ID.to_s)
      { not: WINE_VOLUME_BLACKLIST }
    end
  end

  def filter_brand_ids
    if @params[:brand].present?
      brand_ids =
        begin # using find allows id or permalink
          Brand.find(@params[:brand]).self_and_sub_brand_ids
        rescue ActiveRecord::RecordNotFound
          [] # if invalid input, want a value that no variant will match
        end
    end
    brand_ids || []
  end

  def filter_price_range
    @params[:price].present? ? @params[:price][:min]..@params[:price][:max] : nil
  end

  def facet_price_ranges
    case @params[:category]
    when 'wine'
      [{ to: 11 }, { from: 11, to: 16 }, { from: 16 }]
    when 'liquor'
      [{ to: 24 }, { from: 24, to: 50 }, { from: 50 }]
    else
      [{ to: 20 }, { from: 20, to: 40 }, { from: 40 }]
    end
  end
end
