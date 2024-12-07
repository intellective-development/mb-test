class ProductGroupingSearch::FeaturedProducts < ProductGroupingSearch::Base
  attr_reader :supplier_ids, :user, :options

  BASE_SEARCH_FILTERS = {
    active: true,
    searchable: true,
    root_type: %w[wine beer liquor mixers]
  }.freeze

  DEFAULT_PRICE_MIN = 8
  DEFAULT_PRICE_MAX = 80

  DEFAULT_PRODUCT_COUNT = 8

  def initialize(options, user, visit = nil)
    @supplier_ids = options[:supplier_ids] if options[:supplier_ids].present?
    @user = user
    @visit = visit
    @profile = @user&.profile || @visit&.profile
    @options = options
    @has_suppliers = options[:supplier_ids].present?
    super()
  end

  def search_options
    {
      where: filters(@options, @user),
      aggs: [],
      boost_by: %i[popularity_60day has_image],
      boost_where: boost(@options, @user),
      limit: limit(@options),
      load: false
    }
  end

  def nested_matches
    matches = super

    price_min = @options.dig('price', 'min') || DEFAULT_PRICE_MIN
    price_max =
      if @options.dig('price', 'max')
        @options.dig('price', 'max')
      elsif @user&.profile && !@options[:only_previous]
        (@user.profile.max_price + 25).to_i
      else
        DEFAULT_PRICE_MAX
      end

    matches << { range: { 'variants.price' => { 'gt' => price_min } } }
    matches << { range: { 'variants.price' => { 'lt' => price_max } } }

    matches
  end

  def search
    if @has_suppliers
      super
    else
      ProductSizeGrouping.search(@query, search_options)
    end
  end

  def get_views(results, max_suppliers: nil)
    # TODO: Do we have duplicates if multiple of our suppliers have this grouping?
    # TODO: this method takes about 110ms, 60ms in the DB and another 50ms outside of it. That extra 50ms can probably be improved
    if @has_suppliers
      super
    else
      grouping_ids = results.map(&:id)
      ProductGroupingStoreView.retrieve_without_variants(grouping_ids).to_a
    end
  end

  private

  def boost(options, _user = nil)
    boost = {}

    if options[:product_grouping_similarity_type] == 'collaborative' && options[:product_grouping_ids]&.any?
      # high enough factor such that it will always take precendence over user profile boosts
      boost[:frequently_ordered_with] = { value: options[:product_grouping_ids], factor: 10_000 }
    end

    boost.merge(personalization_boost(@profile))
  end

  def limit(options)
    limit = (options[:count] || DEFAULT_PRODUCT_COUNT)
    limit *= 3 if options[:dynamic].present?
    limit
  end

  def filters(options, user)
    filters = BASE_SEARCH_FILTERS.dup

    similarity_filters = filter_by_grouping_similarity(options) if options[:product_grouping_ids]&.any?
    filters.merge!(similarity_filters) if similarity_filters

    previously_ordered_id_filters = filter_previously_ordered(options, user)
    filters[:id] = previously_ordered_id_filters if previously_ordered_id_filters.any?

    filters[:tags]          = options[:tags]             if options[:tags].present?
    filters[:ancestor_ids]  = options[:product_type_id]  if options[:product_type_id].present?

    filters
  end

  def filter_by_grouping_similarity(options)
    product_groupings = ProductSizeGrouping.where_identifier(options[:product_grouping_ids])

    filters = {}

    if product_groupings.any?
      filters[:id] = { not: product_groupings.map(&:id) } # need to always get the numeric ids
      filters[:ancestor_ids] = product_groupings.map(&:product_type_id).uniq if options[:product_grouping_similarity_type] == 'content'
    end

    filters
  end

  protected

  def build_body(body)
    super

    if options[:preferred_supplier_id].present?
      boost_variant_id = {
        filter: {
          nested: {
            path: 'variants',
            query: {
              bool: {
                should: [
                  {
                    match: {
                      "variants.supplier_id": options[:preferred_supplier_id].to_i
                    }
                  }
                ]
              }
            }
          }
        },
        weight: 11
      }
      body[:query][:function_score][:functions].push boost_variant_id
    end
  end
end
