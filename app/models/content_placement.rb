# == Schema Information
#
# Table name: content_placements
#
#  id                   :integer          not null, primary key
#  name                 :string(255)
#  content_type         :integer
#  default_promotion_id :integer
#  created_at           :datetime
#  updated_at           :datetime
#
# Indexes
#
#  index_content_placements_on_name  (name) UNIQUE
#

class ContentPlacement < ActiveRecord::Base
  enum content_type: {
    promotion: 0, # Generic Promotional Banners
    multi_promotion: 5, # Promotional Content like the web homepage banners
    featured_product: 1, # Selection of product recommendations
    search_suggestions: 3, # Suggestions for a given search term from other suppliers
    enhanced_pdp: 4, # Enhanced PDP content, corresponds to ProductContent model
    product_type: 6 # Product Type banners
  }

  validates :name, presence: true, uniqueness: true

  belongs_to :default_promotion, class_name: 'Promotion'

  has_many :promotions

  BASE_SEARCH_FILTERS = {
    active: true,
    in_stock: true,
    searchable: true
  }.freeze

  SEARCH_INCLUDES = [:variant_store_view].freeze

  def entity(options, user = nil, suppliers = [], _auth_header = '')
    content = select_content(options, user)
    options = { placement_name: name, has_suppliers: suppliers&.any?, user: user, context: options }
    select_entity&.represent(content, options)
  end

  def select_content(options, user = nil, _count = 1)
    case content_type
    when 'promotion'          then select_promotion(options, user)
    when 'multi_promotion'    then select_multi_promotion(options, user)
    when 'featured_product'   then select_featured_product(options, user)
    when 'search_suggestions' then select_search_suggestions(options, user, auth_header)
    when 'enhanced_pdp'       then select_product_content(options, user)
    when 'product_type'       then select_product_type(options, user)
    end
  end

  private

  def select_entity
    case content_type
    when 'promotion'          then ConsumerAPIV2::Entities::ContentPromotion
    when 'multi_promotion'    then ConsumerAPIV2::Entities::ContentMultiPromotion
    when 'featured_product'   then ConsumerAPIV2::Entities::ContentProduct
    when 'search_suggestions' then ConsumerAPIV2::Entities::ContentSearchSuggestions
    when 'enhanced_pdp'       then ConsumerAPIV2::Entities::ContentEnhancedProductDetail
    when 'product_type'       then ConsumerAPIV2::Entities::ContentMultiProductType
    end
  end

  def select_promotion(options, user)
    promotions = available_promotions(options, user)
    top_priority = promotions.map(&:priority).min
    promotions.select { |p| p.priority == top_priority }.sample
  end

  def select_multi_promotion(options, user)
    count = options[:count] || 1
    promotions = available_promotions(options, user)[0..(count.to_i - 1)]
    { content: promotions }
  end

  def available_promotions(options, user)
    if promotions.any?
      suppliers = options[:supplier_ids] || []
      # FIXME: We don't need to iterate through suppliers here (I think)
      eligible_promotions = suppliers.flat_map do |supplier_id|
        promotions.active.at(Time.zone.now).for_supplier(supplier_id).select do |promo|
          exclude_logged_out = (promo.exclude_logged_in_user ? user.nil? : true)
          exclude_logged_in  = (promo.exclude_logged_out_user ? user.present? : true)
          promo.eligible?(options.symbolize_keys) && exclude_logged_out && exclude_logged_in
        end
      end
      chosen_promotions = eligible_promotions.flatten.uniq.sort_by(&:priority)
    elsif default_promotion
      chosen_promotions = default_promotion
    end

    Array(chosen_promotions)
  end

  def select_product_content(options, _user)
    identifier = dynamic_id(options[:dynamic_id]) if options[:dynamic_id]
    identifier ||= name

    # TODO: we likely do not need the variant or product cases
    model = if options[:variant_id]
              Variant.includes(product: [:product_content]).find_by(id: options[:variant_id])
            elsif options[:product_id]
              Product.includes(:product_content).find_by(permalink: options[:product_id])
            elsif options[:product_grouping_ids]
              ProductSizeGrouping.includes(:product_content).find_by_identifier(options[:product_grouping_ids])
            end
    product_content = model&.product_content&.active ? model.product_content : false

    # TODO: Handle Multiple Templates
    if product_content
      {
        id: identifier,
        impression_tracking_id: impression_tracking_id,
        click_tracking_id: click_tracking_id,
        content: {
          template: product_content.template,
          primary_background_color: product_content.primary_background_color,
          secondary_background_color: product_content.secondary_background_color,
          video: {
            mp4: product_content.video_mp4(:url),
            poster: product_content.video_poster(:url)
          }
        }
      }
    else
      {
        id: identifier,
        impression_tracking_id: false,
        click_tracking_id: false,
        content: false
      }
    end
  end

  def select_search_suggestions(options, user, auth_header)
    # Create a temporary address object and find all eligible suppliers that
    # service that address.
    address = Address.create_from_params(options[:address])
    ls = LocationServices.new(address, select_multiple_suppliers: true)

    available_suppliers = ls.find_suppliers(Storefront.find(Storefront::MINIBAR_ID))
    available_supplier_ids = available_suppliers.collect(&:id)

    # Find search suggestion products and supplier.
    suggestions = search_suggestions(options, user, available_supplier_ids, auth_header)
    product_groupings = suggestions[:product_groupings]
    supplier = Supplier.find_by(id: suggestions[:supplier_id])

    # Including shipping methods here as it needs to be sent back to the entity.
    {
      impression_tracking_id: impression_tracking_id,
      click_tracking_id: click_tracking_id,
      content: {
        supplier: supplier,
        product_groupings: product_groupings[0..2],
        total_results: product_groupings.size
      },
      _shipping_methods: ls.shipping_methods
    }
  end

  def search_suggestions(options, _user, available_supplier_ids, auth_header)
    # TODO: split this method up, so we can do things like test the alternative ids properly, the results, the chosen supplier, etc

    search_params = options['browse_context']

    # Remove the users current suppliers (options[:supplier_ids]) from the set of eligible suppliers (available_supplier_ids)
    alternate_supplier_ids = available_supplier_ids.map(&:to_s) - options[:supplier_ids].map(&:to_s)
    search_params[:supplier_ids] = alternate_supplier_ids

    # TODO: - Catch this rather than sending 500 back to the client.
    raise 'Search suggestions failed - no alternate suppliers available.' unless alternate_supplier_ids.any?

    uri = "/api/v2/supplier/#{search_params[:supplier_ids].join(',')}/product_groupings?#{search_params.to_query}"
    response = LambdaEndpointsService.call_lambda(uri, auth_header)

    supplied_by_ids = ProductSizeGrouping.supplied_by(response['product_groupings'].map { |pg| pg['id'] }).map(&:to_s)
    supplier_id = (supplied_by_ids & alternate_supplier_ids).first

    product_groupings = ProductSizeGrouping.get_views_from_es_result(response, [supplier_id]) if supplier_id
    product_groupings ||= []

    { supplier_id: supplier_id, product_groupings: product_groupings }
  end

  def select_featured_product(options, user)
    product_groupings = featured_product_groupings(options, user)

    # TODO: needs to be updated to be dynamic
    identifier = dynamic_id(options[:dynamic_id]) if options[:dynamic_id]
    identifier ||= name

    {
      impression_tracking_id: impression_tracking_id,
      click_tracking_id: click_tracking_id,
      id: identifier,
      content: product_groupings
    }
  end

  def featured_product_groupings(options, user)
    Rails.cache.fetch("content_placement::featured_product_groupings::#{options}::#{user}", expires_in: 24.hours) do
      searcher = ProductGroupingSearch::FeaturedProducts.new(options, user)
      results = searcher.search
      views = Array(searcher.get_views(results))
      views.compact.sample(options[:count] || 8)
    end
  end

  def select_product_type(options, user)
    options[:per_page] = options[:count]
    popular_types = ProductTypeSearchService.search_popular(options, user)
    { content: popular_types }
  end

  def click_tracking_id
    "#{name}__click"
  end

  def impression_tracking_id
    "#{name}__impression"
  end

  def dynamic_id(extra_identifier)
    "#{name}__#{extra_identifier}" if extra_identifier
  end
end
