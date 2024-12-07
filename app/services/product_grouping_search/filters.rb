# frozen_string_literal: true

class ProductGroupingSearch::Filters
  attr_reader :results, :params, :query

  DEFAULT_VARIANT_ORDER = 'volume'
  WILDCARD_QUERY = '*'
  NESTED_PROPS = %w[price container_type volume selected_supplier delivery_type].freeze
  PROPS_LIST = %w[tags ancestor_ids brand_id hierarchy_category hierarchy_type hierarchy_subtype country].concat(NESTED_PROPS)

  def initialize(query = WILDCARD_QUERY)
    @query = query
    @supplier_ids ||= []
    @agg_list = params[:facet_list] || []
  end

  # ----------------------------------
  def price_ranges_from_params(prices)
    {
      bool: {
        should: prices.map do |price_range|
          pr = {}
          pr[:gt] = price_range[0] if price_range[0].is_a? Numeric
          pr[:lte] = price_range[1] if price_range[1].is_a? Numeric
          { 'range': { 'variants.price': pr } }
        end
      }
    }
  end

  def nested_search_terms(terms)
    # nested (variant's attrs) terms being search by client in this request
    terms & @params.keys.map(&:to_s)
  end

  def get_nested_terms(terms_to_add, for_facets)
    nested_terms = []
    nested_terms << { match: { 'variants.case_eligible': true } }                      if @params[:only_case_deals]
    nested_terms << { range: { 'variants.two_for_one': { gte: 0 } } }                  if @params[:only_two_for_one]
    nested_terms << { terms: { "variants.container_type": @params[:container_type] } } if terms_to_add.include?('container_type') && @params[:container_type].present?
    nested_terms << { terms: { "variants.volume": @params[:volume] } }                 if terms_to_add.include?('volume') && @params[:volume].present?
    nested_terms.push(price_ranges_from_params(@params[:price]))                       if terms_to_add.include?('price') && @params[:price].present?

    if nested_terms.present? || for_facets
      nested_terms << { term: { 'variants.active': true } }
      nested_terms << { range: { 'variants.in_stock': { gte: 1 } } }
      nested_terms << { terms: { 'variants.supplier_id': terms_to_add.include?('selected_supplier') ? @selected_suppliers : @supplier_ids } }
    end

    nested_terms
  end

  def nested_filter_base(filter)
    {
      nested: {
        path: 'variants',
        inner_hits: { size: 100 }, # THIS allows us to shrink variants to query conditions
        query: { bool: { filter: filter } }
      }
    }
  end

  def create_term(key, value)
    term = value.is_a?(Array) ? 'terms' : 'term'
    Hash[term, Hash[key, value]]
  end

  def get_terms(terms_to_add = nil, for_facets = false)
    terms_to_add ||= get_props_list
    terms = []

    terms << { terms: { available_supplier_ids: @selected_suppliers || @supplier_ids } } if @selected_suppliers.present? || @supplier_ids.present?
    # TODO: is it ok to get root level filters from where?
    search_options[:where].each do |key, value|
      terms << create_term('_id', value[:in]) if key == :id && value.is_a?(Hash) && value[:in].present?
      terms << create_term(key, value) if terms_to_add.include?(key.to_s) # TODO: do we need this check here
    end
    nested_filter = get_nested_terms(terms_to_add, for_facets)
    terms << nested_filter_base(nested_filter) if nested_filter.present?
    terms
  end

  def get_not(_where)
    terms = []
    not_in = search_options.dig(:where, :id, :not)
    terms << create_term('_id', not_in) if not_in.present?
    terms
  end

  def get_buckets(buckets)
    buckets.map do |b|
      b['doc_count'] = b['root_doc']['doc_count'] if b.present?
      b
    end
  end

  def nested_variants_aggs_field(field)
    # reverse nested allows to count product_groupings instead of variants that are nested
    { terms: { field: field, size: 1000 }, aggs: { root_doc: { reverse_nested: {} } } }
  end

  def nested_variants_aggs_price_range
    # reverse nested allows to count product_groupings instead of variants that are nested
    {
      range: { field: 'variants.price', ranges: [{ to: 20.0 }, { from: 20.0, to: 40.0 }, { from: 40.0 }] },
      aggs: { root_doc: { reverse_nested: {} } }
    }
  end

  def get_key_field_for_facet(facet)
    case facet
    when 'selected_supplier', 'delivery_type'
      'supplier_id'
    when 'brand'
      'brand_id'
    else
      facet
    end
  end

  def get_agg_for_facet(facet)
    field = get_key_field_for_facet(facet)
    if get_nested_props.include?(facet)
      agg = {
        nested: { path: 'variants' },
        aggs: {
          nested: {
            filter: { bool: { filter: get_nested_terms(get_nested_props - [facet], true) } },
            aggs: {}
          }
        }
      }
      agg[:aggs][:nested][:aggs][:inner] = facet == 'price' ? nested_variants_aggs_price_range : nested_variants_aggs_field("variants.#{field}")
    else
      agg = {
        terms: {
          field: field,
          size: 1000
        }
      }
    end

    agg
  end

  def aggregate_many(facet_list, aggs)
    facet_list = facet_list.map { |x| x == 'brand' ? 'brand_id' : x }
    agg_result = ProductSizeGrouping.search(@query, search_options) do |body|
      body.delete(:sort) # we don't need to sort here
      body[:query] = @query.eql?(WILDCARD_QUERY) ? body[:query] : body[:query][:function_score][:query]
      body[:query] = body[:query][:function_score][:query] if body[:query][:bool].nil? && body[:query][:function_score].present?

      prop_list = get_props_list
      # we want to get only the current hierarchy_type if it is selected
      prop_list -= facet_list unless facet_list.size == 1 && facet_list[0] == 'hierarchy_type'
      body[:query][:bool][:filter] = get_terms(prop_list, true)
      body[:query][:bool][:must_not] = get_not(search_options[:where])
      body[:size] = 0
      body[:aggs] ||= {}
      facet_list.each { |facet| body[:aggs][facet] = get_agg_for_facet(facet) }
      Rails.logger.debug "---- #{facet_list} facet query ----\\n#{facet_list}\\n#{body.to_json}\\n---- end #{facet_list} facet query ----"
      body
    end
    facet_list.each do |facet|
      if get_nested_props.include?(facet)
        value = agg_result.aggs[facet]['nested']['inner']
        aggs[facet == 'brand_id' ? 'brand' : facet] = Hash['buckets', get_buckets(value['buckets'])] if value.is_a?(Hash)
      else
        aggs[facet == 'brand_id' ? 'brand' : facet] = agg_result.aggs[facet]
      end
    end
    aggs
  end

  def aggregate(facet, aggs)
    aggregate_many([facet], aggs)
  end

  def get_agg_for_sponsored_brand
    field = '_uid'
    {
      terms: {
        "field": 'brand_id'
      },
      aggs: {
        top_product_hits: {
          top_hits: {
            size: 3,
            sort: [{ 'popularity_60day': :desc }]
          }
        }
      }
    }
  end

  def sponsored_search
    sponsored_result = ProductSizeGrouping.search(@query, search_options) do |body|
      body[:query] = @query.eql?(WILDCARD_QUERY) ? body[:query] : body[:query][:function_score][:query]
      body[:query] = body[:query][:function_score][:query] if body[:query][:bool].nil? && body[:query][:function_score].present?
      brand_term = {
        "term": {
          "sponsored_brand": true
        }
      }

      filters = get_terms(get_props_list, true)
      filters << brand_term
      body[:query][:bool][:filter] = filters

      body[:query][:bool][:must_not] = get_not(search_options[:where])
      body[:size] = 0
      body[:aggs] ||= {}
      body[:aggs]['sponsored_brands'] = get_agg_for_sponsored_brand
      nested_sort(body, { bool: { filter: get_nested_terms(get_nested_props, true) } })
      Rails.logger.debug "---- sponsored query ----\\n#{body.to_json}\\n---- end sponsored query ----"
      body
    end
    sponsored_result = ProductGroupingSearch::FiltersResults.new(sponsored_result)
  end

  def search
    results = {}
    threads = [Thread.new do
      results = ProductSizeGrouping.search(@query, search_options) do |body|
        body[:query] = @query.eql?(WILDCARD_QUERY) || !body[:query][:function_score].present? ? body[:query] : body[:query][:function_score][:query]
        body[:query] = body[:query][:function_score][:query] if body[:query][:bool].nil? && body[:query][:function_score].present?
        body[:query] ||= {}
        body[:query][:bool] ||= {}
        body[:query][:bool][:filter] = get_terms(get_props_list)
        body[:query][:bool][:must_not] = get_not(search_options[:where])
        nested_sort(body, { bool: { filter: get_nested_terms(get_nested_props, true) } })
        Rails.logger.debug "---- filter query ----\\n#{body.to_json}\\n---- end filter query ----"
        body
      end
    end]
    # TODO: include conditions below
    # aggs[:hierarchy_type] = { where: filters.except(:hierarchy_type, :hierarchy_subtype) } if agg_list.include?('hierarchy_type') && (@params[:base] == 'hierarchy_category' || @params[:hierarchy_category])

    has_legacy_type_filter = @params[:type].present? && !ProductType.find_by(permalink: @params[:type])&.root?
    facet_list = params[:facet_list] || []
    if facet_list.present?
      facet_list -= ['delivery_type'] # we don't aggregate it in elasticsearch
      facet_list -= ['hierarchy_category']  if @params[:base] == 'hierarchy_category' || !facet_list.include?('hierarchy_category')
      facet_list -= ['hierarchy_type']      unless facet_list.include?('hierarchy_type') && (@params[:base] == 'hierarchy_category' || @params[:hierarchy_category])
      facet_list -= ['hierarchy_subtype']   unless facet_list.include?('hierarchy_subtype') && (@params[:hierarchy_type] || has_legacy_type_filter)
    end

    # aggs = facet_list.reduce({}) { |acc, facet| aggregate(facet, acc) }
    aggs = {}
    aggregate('delivery_type', aggs) if (params[:facet_list] || []).include?('delivery_type')
    # Facets that are not search options can be grouped together (they share ES filter)

    search_terms = search_options[:where].keys.map(&:to_s)
    search_terms += nested_search_terms(get_nested_props) # TECH-2959
    search_terms = search_terms.map { |s| s == 'brand_id' ? 'brand' : s }
    aggregate_many(facet_list - search_terms, aggs) unless facet_list.empty?
    # Facets that are search options should be queried in separate (ES filters exclude themselves)
    threads += (facet_list & search_terms).map { |facet| Thread.new { aggregate(facet, aggs) } } unless facet_list.empty?

    ActiveSupport::Dependencies.interlock.permit_concurrent_loads { threads.each(&:join) }

    # modify global variables at the end to get proper results for delivery type aggregation
    @supplier_ids = @selected_suppliers || params[:supplier_ids]

    results = ProductGroupingSearch::FiltersResults.new(results)
    results.aggs = aggs
    results
  end

  def get_views(results, supplier_ids = nil, max_suppliers: nil)
    # TODO: Do we have duplicates if multiple of our suppliers have this grouping?
    # TODO: this method takes about 110ms, 60ms in the DB and another 50ms outside of it. That extra 50ms can probably be improved
    grouping_ids = results.map(&:id)
    variant_ids = results.map(&:inner_hits).map(&:variants).map(&:hits).map(&:hits).flatten.map(&:_source).map(&:variant_id)
    supplier_ids ||= @supplier_ids # default params to the instance var
    if max_suppliers.present?
      supplier_ids &= results.map(&:inner_hits).map(&:variants).map(&:hits).map(&:hits).flatten.map(&:_source).map(&:supplier_id)
      supplier_ids = supplier_ids
                     .uniq
                     .first(max_suppliers.to_i)
    end
    ProductGroupingStoreView.retrieve_from_variants(grouping_ids, variant_ids, supplier_ids, variant_order).to_a
  end

  def facet_price_ranges
    if @params.present? && @params[:category] == 'wine'
      [{ to: 11 }, { from: 11, to: 16 }, { from: 16 }]
    elsif @params.present? && @params[:category] == 'liquor'
      [{ to: 24 }, { from: 24, to: 50 }, { from: 50 }]
    else
      [{ to: 20 }, { from: 20, to: 40 }, { from: 40 }]
    end
  end

  def nested_suppliers(supplier_ids = [])
    supplier_ids = supplier_ids.presence || @supplier_ids
    { 'terms' => { 'variants.supplier_id' => supplier_ids } }
  end

  def nested_sort(*options)
    # to be implemented by child
  end

  def search_options
    # to be implemented by child
  end

  def get_nested_props
    NESTED_PROPS
  end

  def get_props_list
    PROPS_LIST
  end

  def variant_order
    DEFAULT_VARIANT_ORDER
  end

  # TODO: Do we need to use the ordered categories/types/subtypes here? Do we get better
  #       results simply using the recently and most ordered.
  def personalization_boost(profile)
    boost = {}

    if profile
      boost[:orderer_ids_60day] = { value: profile&.user&.id, factor: 1000 }       if profile&.user&.id
      boost[:product_type_id] = { value: profile.most_popular_type, factor: 1000 } if profile.most_popular_type

      boost[:hierarchy_category] = [
        { value: profile.viewed_categories, factor: 1 },
        { value: profile.added_categories, factor: 2 },
        { value: profile.ordered_categories, factor: 1 },
        { value: profile.recently_ordered_categories, factor: 2 },
        { value: profile.most_ordered_categories, factor: 3 }
      ].reject { |i| i[:value].empty? }
      boost[:hierarchy_type] = [
        { value: profile.viewed_types, factor: 5 },
        { value: profile.added_types, factor: 20 },
        { value: profile.ordered_types, factor: 10 },
        { value: profile.recently_ordered_types, factor: 20 },
        { value: profile.most_ordered_types, factor: 30 }
      ].reject { |i| i[:value].empty? }
      boost[:hierarchy_subtype] = [
        { value: profile.viewed_subtypes, factor: 75 },
        { value: profile.added_subtypes, factor: 200 },
        { value: profile.ordered_subtypes, factor: 100 },
        { value: profile.recently_ordered_subtypes, factor: 200 },
        { value: profile.most_ordered_subtypes, factor: 300 }
      ].reject { |i| i[:value].empty? }
    end

    boost
  end

  def filter_previously_ordered(options, user)
    filter = {}

    # if no user, treating as if no previous order items
    previous_order_items = user&.previous_order_items || []

    filter[:not] = previous_order_items if options[:exclude_previous]
    filter[:in] = previous_order_items if options[:only_previous]
    filter
  end
end
