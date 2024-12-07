class ConsumerAPIV2::AutocompleteEndpoint < BaseAPIV2
  require 'searchkick'

  SPONSORED_COUNT = 3

  SEARCH_FIELDS = ['name^75', { 'name^75' => :word_start }, 'keywords^50'].freeze

  PRODUCT_CONFIG = {
    fields: SEARCH_FIELDS,
    where: {
      active: true
    },
    order: [{ 'gift_card': :desc, 'popularity_60day': :desc }],
    load: false
  }.freeze

  CATEGORY_CONFIG = {
    fields: %i[name synthetic_name], # So Wine/Red will rank above Wine/Red/CabernetFranc
    misspellings: false
  }.freeze

  BRAND_CONFIG = {
    fields: [:brand],
    select: %i[brand_id brand_name brand_permalink],
    includes: [:brand],
    limit: 20, # larger as we will have more duplicates
    where: {
      active: true
    },
    order: [{ 'popularity_60day': :desc }]
  }.freeze

  desc 'Get autocomplete list', ConsumerAPIV2::DOC_AUTH_HEADER
  resource 'autocomplete' do
    params do
      requires :query, type: String, desc: 'Search query', allow_blank: false
      optional :supplier_ids, type: Array, desc: 'Users supplier_ids', default: []
      optional :alternative_supplier_ids, type: Array, desc: 'Users alternative_supplier_ids', default: []
    end

    route_param :query do
      get do
        results_length = 10

        searchers = create_searchers(params)
        # Retry misspellings was breaking supplier_id matching, and so was turned off
        # If turned on, a second retry_misspellings: true param may be needed until SK upgrade: https://github.com/ankane/searchkick/pull/966
        Searchkick.multi_search(searchers.map { |_, searcher| searcher })

        searchers[:brand] = format_products_as_brands(searchers[:brand]) if searchers.key?(:brand)
        searchers[:sponsored_product] = parse_sponsored_results(searchers[:sponsored_product])
        results = searchers.flat_map { |type, result_list| result_list.map { |result| { type: type, result: result } } }
        results = sort_results(results).slice(0, results_length)
        results = filter_duplicate_products(results)

        present :query, params[:query]
        present :results, results, with: ConsumerAPIV2::Entities::AutocompleteResult, platform: client_details.platform
      end
    end
  end

  helpers do
    def create_searchers(params)
      alternative_supplier_ids = params[:alternative_supplier_ids]
      supplier_ids = params[:supplier_ids].reject { |supplier_id| supplier_id == '_' }

      base_search_config = {
        fields: ['name^75', { 'name^75' => :word_start }, 'synthetic_name^75', { 'synthetic_name^75' => :word_start }],
        select: %i[id name permalink thumb_url image_url_mobile image_url_web gift_card],
        limit: 10,
        execute: false
      }

      searchers = {
        category: ProductType.search(params[:query], base_search_config.merge(CATEGORY_CONFIG))
      }

      if supplier_ids.any?
        brand_searcher = ProductGroupingSearch::Autocomplete.new(params[:query], supplier_ids, base_search_config.merge(BRAND_CONFIG))
        searchers[:brand] = brand_searcher.search

        product_searcher = ProductGroupingSearch::Autocomplete.new(params[:query], supplier_ids, base_search_config.merge(PRODUCT_CONFIG))
        searchers[:product] = product_searcher.search

        searchers[:sponsored_product] = product_searcher.sponsored_search
      end

      if alternative_supplier_ids.any?
        alternative_product_searcher = ProductGroupingSearch::Autocomplete.new(params[:query], alternative_supplier_ids, base_search_config.merge(PRODUCT_CONFIG))
        searchers[:search] = alternative_product_searcher.search
      end

      searchers
    end

    def parse_sponsored_results(results)
      return results unless results.is_a?(Searchkick::Query)

      buckets = results.aggregations['sponsored_brands']['buckets']
      products = []
      if buckets.is_a?(Array)
        buckets = buckets.reject { |buck| (buck['doc_count']).zero? }
        bucket_pick = 1
        next_bucket_pick = SPONSORED_COUNT + bucket_pick - buckets.size
        buckets.each_with_index do |bucket, _index|
          bucket_pick = products.size < SPONSORED_COUNT ? next_bucket_pick : 0
          if next_bucket_pick > bucket['top_product_hits']['hits']['hits'].size
            bucket_pick = bucket['top_product_hits']['hits']['hits'].size
            next_bucket_pick -= bucket['top_product_hits']['hits']['hits'].size
          else
            next_bucket_pick = 1
          end
          bucket_pick.times do |i|
            product = bucket['top_product_hits']['hits']['hits'][i]['_source']
            product['id'] = product['product_grouping_id']
            product['inner_hits'] = bucket['top_product_hits']['hits']['hits'][i]['inner_hits']
            product['sponsored'] = true
            products << product
          end
        end
      end

      json_data = products.to_json
      JSON.parse(json_data, object_class: OpenStruct)
    end

    def filter_duplicate_products(results)
      # We don't want to show products both from current and alternate stores
      product_ids = results.select { |r| r[:type] == :product || r[:type] == :sponsored_product }.map { |r| r[:result][:id] }
      results.reject { |result| result[:type] == :search && product_ids.include?(result[:result][:id]) }.uniq { |result| "#{result[:type] == :sponsored_product ? :product : result[:type]}#{result[:result][:id]}" }
    end

    def sort_results(results)
      order = %i[category sponsored_product product brand search]
      results.sort_by do |result|
        # show gift_card products first
        (order.index result[:type]) + (result[:type] == :product && result[:result].gift_card ? 0 : 0.5)
      end
    end

    def format_products_as_brands(results)
      results = results.map do |result|
        {
          id: result[:brand_id],
          name: result.brand&.name,
          permalink: result.brand&.permalink
        }
      end
    end
  end
end
