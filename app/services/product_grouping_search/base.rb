# frozen_string_literal: true

class ProductGroupingSearch::Base
  attr_reader :results, :params, :query

  DEFAULT_VARIANT_ORDER = 'volume'
  WILDCARD_QUERY = '*'

  def initialize(query = WILDCARD_QUERY)
    @query = query
    @supplier_ids ||= []
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
    ProductSizeGrouping.search(@query, search_options) do |body|
      brand_term = {
        "term": {
          "sponsored_brand": true
        }
      }

      body[:query] ||= {}
      body[:query][:bool] ||= {}
      body[:query][:bool][:must] ||= []

      must_arr = []
      must_arr << brand_term
      body[:query][:bool][:filter] = [{ terms: { available_supplier_ids: @supplier_ids } }] if @supplier_ids.present?
      must_arr << body[:query][:bool][:must] if body[:query][:bool][:must].is_a?(Hash)

      body[:query][:bool][:must] = must_arr
      body[:size] = 0
      body[:aggs] ||= {}
      body[:aggs]['sponsored_brands'] = get_agg_for_sponsored_brand

      Rails.logger.debug "---- sponsored query ----\\n#{body.to_json}\\n---- end sponsored query ----"
      body
    end
  end

  def search
    ProductSizeGrouping.search(@query, search_options) do |body|
      build_body body
    end
  end

  def get_views(results, supplier_ids = nil, max_suppliers: nil)
    # TODO: Do we have duplicates if multiple of our suppliers have this grouping?
    # TODO: this method takes about 110ms, 60ms in the DB and another 50ms outside of it. That extra 50ms can probably be improved
    grouping_ids = results.map(&:id)
    supplier_ids ||= @supplier_ids # default params to the instance var
    if max_suppliers.present?
      supplier_ids &= results.map(&:variants).flatten.map(&:supplier_id)
      supplier_ids = supplier_ids
                     .uniq
                     .first(max_suppliers.to_i)
    end
    ProductGroupingStoreView.retrieve_with_variants(grouping_ids, supplier_ids, variant_order).to_a
  end

  def nested_matches
    # overidden by some children
    [
      { range: { 'variants.in_stock' => { gte: 1 } } },
      { match: { 'variants.active' => true } }
    ]
  end

  def nested_suppliers(supplier_ids = [])
    supplier_ids.map { |id| { 'term' => { 'variants.supplier_id' => id } } }
  end

  def nested_sort(*options)
    # to be implemented by child
  end

  def search_options
    # to be implemented by child
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
    filter[:in] = previous_order_items  if options[:only_previous]
    filter
  end

  protected

  def build_body(body)
    # Query placement depends on whether or not function score is enabled
    query_level = body[:query][:function_score].nil? ? body : body[:query][:function_score]

    query_level[:query] ||= {}
    query_level[:query][:bool] ||= {}
    query_level[:query][:bool][:must] ||= []
    query_level[:query][:bool][:filter] ||= []

    must_arr = []
    body[:query][:bool][:filter] = [{ terms: { available_supplier_ids: @supplier_ids } }] if @supplier_ids.present?
    must_arr << query_level[:query][:bool][:must] if query_level[:query][:bool][:must].is_a?(Hash)

    query_level[:query][:bool][:must] = must_arr

    # body[:query][:bool][:must].delete(:match_all) if body.dig(:query, :bool, :must, :match_all) == {}

    # When aggs are used, Searchkick turns `filter` into `post_filter`, this is not the
    # behavior so we need to restore filters.
    # body.dig(:post_filter, :bool, :filter)&.each do |filter|
    #   body[:filter][:and] << filter
    #  end

    # apply nested query to each facet
    if body[:aggs].present?
      body[:aggs].each do |_agg_key, agg_query|
        agg_query[:filter][:bool][:must] << { nested: variant_query }
      end
    else
      # Ensure correct post filters - this is necessary if there are no aggs.
      body[:post_filter] = query_level[:query][:bool][:must].find { |k, _v| k == 'nested' }
    end

    # A compact! may work here.
    body.delete(:post_filter) if body[:post_filter].nil?
  end
end
