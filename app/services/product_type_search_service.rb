# frozen_string_literal: true

module ProductTypeSearchService
  SEARCH_FIELDS = ['name^75', 'keywords^50'].freeze

  WILDCARD_QUERY = '*'
  DEFAULT_PER_PAGE = 4
  DEFAULT_POPULAR_FILTERS = {
    has_banner_image: true,
    supplier_ids: [],
    active: true,
    # TODO: remove level restriction when we have better support for sending plp filters from the server
    level: ProductType::LEVEL_NAME_MAP[:type]
  }.freeze

  def self.search_popular(options = {}, user = nil)
    options = options.symbolize_keys
    search_params = {}
    search_params[:where]       = popular_filters(options)
    search_params[:boost_by]    = %i[popularity_60day popularity]
    search_params[:boost_where] = popular_boost(user)
    search_params[:fields]      = SEARCH_FIELDS
    search_params[:per_page]    = options[:per_page] || DEFAULT_PER_PAGE
    search_params[:page]        = options[:page] || 1
    search_params[:order]       = order(options[:featured])

    ProductType.search(WILDCARD_QUERY, search_params)
  end

  # Private Methods

  def self.popular_filters(options = {})
    # we can unset the defaults by passing nil,
    # because the nil will override the default value,
    # and will then be removed by the compact.

    filters = options.slice(:supplier_ids, :has_banner_image) # whitelist filters from options
    DEFAULT_POPULAR_FILTERS.merge(filters).compact
  end

  def self.popular_boost(user)
    boost = {}

    if user&.profile
      boost[:id] = [
        # categories
        { value: user.profile.ordered_categories, factor: 10 },
        { value: user.profile.recently_ordered_categories, factor: 20 },
        { value: user.profile.most_ordered_categories, factor: 30 },

        # types
        { value: user.profile.ordered_types, factor: 100 },
        { value: user.profile.recently_ordered_types, factor: 200 },
        { value: user.profile.most_ordered_types, factor: 300 },

        # subtypes
        { value: user.profile.ordered_subtypes, factor: 1000 },
        { value: user.profile.recently_ordered_subtypes, factor: 2000 },
        { value: user.profile.most_ordered_subtypes, factor: 3000 },

        # overall
        { value: user.profile.most_popular_type, factor: 10_000 }
      ]
    end

    boost
  end

  def self.order(banner_featured)
    order = []
    order << { banner_featured_position: :asc } if banner_featured
    order << { _score: :desc } # respect boosts
    order
  end

  private_class_method :popular_filters, :popular_boost, :order
end
