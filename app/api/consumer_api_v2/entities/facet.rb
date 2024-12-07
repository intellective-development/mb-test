class ConsumerAPIV2::Entities::Facet < Grape::Entity
  # Generally, clients will:
  # * Respect the facet names and term descriptions provided by the API.
  # * Render all facets returned from the API that are internally whitelisted.
  #   Facets with an empty terms array will not be sent.
  # * Respect the (sort by count) ordering of terms returned by the API.
  #
  # The `prefer_alpha_flag` serves as a hint to the client that the facet may
  # be more easily groked by the user if the terms are sorted alphabetically.

  ALPHA_SORT = %w[country brand region].freeze
  MULTI_FACET_NAMES = %w[suppliers hierarchy_type hierarchy_subtype country region].freeze
  # https://minibar.atlassian.net/browse/TECH-1803
  ORDERING = %w[delivery_type hierarchy_category hierarchy_type hierarchy_subtype brand price country container_type region volume collection selected_supplier].freeze
  PRODUCT_TYPE_NAMES = %w[hierarchy_category hierarchy_type hierarchy_subtype].freeze

  DISPLAY_NAME_DICTIONARY = {
    'volume': 'size',
    'container_type': 'container',
    'delivery_type': 'delivery',
    'selected_supplier': 'stores',
    'hierarchy_category': 'category',
    'hierarchy_type': 'type'
  }.freeze

  expose :name
  expose :display_name
  expose :index
  expose :multi
  expose :prefer_alpha_sort
  expose :total
  expose :type
  expose :terms
  expose :promoted_terms

  def name
    object[0]
  end

  def hierarchy_type
    hierarchy_types.first
  end

  def promoted_terms
    return [] if hierarchy_type.nil?

    product_type = ProductType.find_by(permalink: hierarchy_type)
    promoted_filter = PromotedFilter.find_by(product_type_id: product_type.id) unless product_type.nil?
    return [] if promoted_filter.nil?

    filter_terms = promoted_filter.facet_promoted_filters[name.to_s]
    return [] if filter_terms.nil?

    result = terms.sort do |a, b|
      index1 = filter_terms.index(a[:term]) || -1
      index2 = filter_terms.index(b[:term]) || -1
      (index1 > -1 ? index1 : Float::INFINITY) - (index2 > -1 ? index2 : Float::INFINITY)
    end

    result.slice(0, 5)
  end

  def display_name
    return object[1]['name'] if object[1]['name']

    return hierarchy_type_display_name if object[0] == 'hierarchy_type'

    return 'Vineyards' if object[0] == 'selected_supplier' && options[:has_vineyard_select]

    if product_type_facet?
      name = object[0].split('_')[1]
      name = 'varietal' if name == 'subtype' && options[:root_types].map(&:name).include?('wine')
    else
      name = object[0]
    end
    String(DISPLAY_NAME_DICTIONARY[:"#{object[0]}"] || name).titleize
  end

  def hierarchy_types
    options[:root_types].map(&:name)
  end

  def hierarchy_type_display_name
    return String(DISPLAY_NAME_DICTIONARY[:"#{object[0]}"]).titleize if hierarchy_types.nil?

    "#{hierarchy_type} Type".titleize
  end

  def prefer_alpha_sort
    ALPHA_SORT.include?(object[0])
  end

  def type
    product_type_facet? ? 'product_type' : object[1]['_type']
  end

  def terms
    return @terms unless @terms.nil?

    if range_facet?
      @terms = object[1]['ranges']
    else
      terms = object[1]['buckets'] # https://minibar.atlassian.net/browse/TECH-1759
      terms = terms_with_type_description(terms) if product_type_facet?
      terms = terms_with_supplier_description(terms) if object[0] == 'selected_supplier'
      terms = terms_with_brand_description(terms) if name == 'brand'
      terms = sort_terms(terms, object[0])
      @terms = reformat_aggregation_to_facets(terms, object[0] != 'selected_supplier')
    end

    @terms
  end

  def total
    object[1]['doc_count'] if range_facet?
  end

  def multi
    MULTI_FACET_NAMES.include?(object[0]) ? true : false
  end

  def index
    ORDERING.index(object[0])
  end

  private

  def range_facet?
    object[1]['_type'] == 'range'
  end

  def product_type_facet?
    PRODUCT_TYPE_NAMES.include?(object[0])
  end

  def terms_with_type_description(terms)
    type_ids = terms.map { |term| term['key'] }
    types = ProductType.where(id: type_ids).group_by(&:id)

    terms.map do |term|
      type = types[term['key']]&.first # types is an array, want to grab the first if found
      term['description'] = type&.name
      term['key'] = type&.permalink
      term
    end
  end

  def sort_volume(volume)
    case volume
    when /packs?$/
      volume.to_f
    when /pack,/
      volume.split(',').inject(1) { |acc, val| sort_volume(val) * acc }
    when /gal$/
      volume.to_f * 3785.412
    when /ml$/
      volume.to_f
    when /L$/
      volume.to_f * 1_000
    when /oz/
      volume.to_f * 29.5735
    else
      volume
    end
  end

  def sort_terms(terms, name)
    return terms if name == 'price'

    if name == 'volume'
      terms.sort_by { |term| NaturalSort(sort_volume(term['key']).to_s) }
    else
      terms.sort_by { |term| NaturalSort(term['description'].presence || term['key']) }
    end
  end

  def terms_with_supplier_description(terms)
    supplier_ids = terms.map { |term| term['key'] }
    types = Supplier.where(id: supplier_ids).order(:name).group_by(&:id)

    described_terms =
      terms.map do |term|
        type = types[term['key']]&.first # types is an array, want to grab the first if found
        term['description'] = type&.display_name || type&.name
        term
      end
    described_terms.sort_by { |term| term['description'] || '' }
  end

  def terms_with_brand_description(terms)
    brand_ids = terms.map { |term| term['key'] }
    brands = Brand.where(id: brand_ids).order(:name).group_by(&:id)

    described_terms =
      terms.map do |term|
        brand = brands[term['key']]&.first # types is an array, want to grab the first if found
        term['description'] = brand&.name || brand&.permalink
        term['key'] = brand&.permalink unless brand&.permalink.nil?
        term
      end
    described_terms.reject { |term| term['description'].nil? }.sort_by { |term| term['description'] }
  end

  # TODO: this is to support the legacy facet syntax that the web store expects
  # Should update store to use the aggregation syntax and pull this out when possible
  def reformat_aggregation_to_facets(terms, should_titleize)
    terms.map do |term|
      description = term['description'] == 'ASAP' ? term['description'] : String(term['description'] || term['key'])
      description = description.titleize if should_titleize
      {
        term: term['key'],
        count: term['doc_count'],
        description: description
      }
    end
  end
end
