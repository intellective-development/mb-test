class BundleService
  DEFAULT_OPTIONS = {
    skip_in_stock_check: false
  }.freeze
  attr_reader :bundle, :suggestions

  # rubocop:disable Metrics/ParameterLists
  def initialize(variant_id, cart_id, business, params, auth_header, cocktail_id = nil, options = {})
    # rubocop:enable Metrics/ParameterLists
    @variant     = Variant.find variant_id if variant_id
    @cart        = Cart.find cart_id if cart_id
    @business    = business
    @cocktail_id = cocktail_id
    @cart_products = @cart.cart_items.active.map { |ci| ci.variant.product_size_grouping } if @cart
    @variant = @cart.cart_items.active.last&.variant if @cart && !@variant
    @auth_header = auth_header
    @params      = params
    @error       = nil
    @options     = DEFAULT_OPTIONS.merge(options)
    @bundle      = find_bundle
    @suggestions = []
  end

  def valid?
    @error.nil?
  end

  def error_args
    [@error.detail, @error.status] if @error.present?
  end

  def find_bundle_options
    return [] unless @bundle

    find_suggestions
  end

  private

  def find_suggestions
    result = []
    product_grouping_ids = []
    brand_ids = []
    product_type_ids = []
    @bundle.bundle_items.each do |item|
      case item.item_type
      when 'ProductSizeGrouping'
        product_grouping_ids << item.item_id
      when 'Brand'
        brand_ids << item.item_id
      when 'ProductType'
        product_type_ids << item.item_id
      end
    end
    result = find_product_groupings_suggestions(product_grouping_ids) unless product_grouping_ids.empty?
    result += find_brand_suggestions(brand_ids) unless brand_ids.empty?
    result += find_product_type_suggestions(product_type_ids) unless product_type_ids.empty?
    @suggestions = result
    result
  end

  def find_groupings_all_suppliers(product_grouping_ids)
    result = []
    uri = "/api/v2/supplier/#{@params[:supplier_ids]}/product_groupings?per_page=#{product_grouping_ids.size}&sort=popularity&sort_direction=desc"
    response = LambdaEndpointsService.call_lambda(uri, @auth_header)
    response.each do |psg|
      result << psg
    end
    result
  end

  def find_product_groupings_suggestions(product_grouping_ids)
    products_to_exclude = @cart_products.map(&:id) if @cart_products
    product_grouping_ids -= products_to_exclude
    result = []
    matched_ids = []
    product_grouping_ids.each do |pg_id|
      view = ProductGroupingStoreView.retrieve_with_variants([pg_id], @variant.supplier.id).first if @variant.present?
      unless view.nil?
        result << view.entity(business: @business)
        matched_ids << pg_id
      end
    end

    remaining_product_grouping_ids = product_grouping_ids - matched_ids
    if @params[:supplier_ids].present? && !remaining_product_grouping_ids.empty?
      remaining_product_grouping_ids.each do |pg_id|
        variants = Variant.active.joins(%i[product_size_grouping inventory])
                          .merge(Inventory.available)
                          .merge(ProductSizeGrouping.where('product_groupings.id = ?', pg_id))
                          .where(supplier_id: @params[:supplier_ids])
                          .limit(1)
        next if variants.nil? || variants.empty?

        # we only want to return variants for 1 supplier
        view = ProductGroupingStoreView.retrieve_with_variants([pg_id], variants.first&.supplier_id).first
        result << view.entity(business: @business) if view
      end
    end
    result
  end

  def find_brand_suggestions(brand_ids)
    exclude_products_filter = get_exclude_products_filters
    result = []
    brand_ids.each do |brand_id|
      response = if @variant.present?
                   uri = "/api/v2/supplier/#{@variant.supplier.id}/product_groupings?per_page=1&sort=popularity&sort_direction=desc&brand%5B%5D=#{brand_id}"
                   uri += "&#{exclude_products_filter.join('&')}" if exclude_products_filter
                   response = LambdaEndpointsService.call_lambda(uri, @auth_header)
                 end
      if response.nil? || response['product_groupings'].empty?
        if @params[:supplier_ids]
          uri = "/api/v2/supplier/#{@params[:supplier_ids].join(',')}/product_groupings?per_page=1&sort=popularity&sort_direction=desc&brand%5B%5D=#{brand_id}"
          uri += "&#{exclude_products_filter.join('&')}" if exclude_products_filter
          response = LambdaEndpointsService.call_lambda(uri, @auth_header)
          next if response.nil? || response['product_groupings'].empty?

          view = ProductGroupingStoreView.retrieve_with_variants([response['product_groupings'][0]['id']], response['product_groupings'][0]['variants'][0]['supplier_id']).first
          result << view.entity(business: @business) unless view.nil?
        end
      else
        view = ProductGroupingStoreView.retrieve_with_variants([response['product_groupings'][0]['id']], response['product_groupings'][0]['variants'][0]['supplier_id']).first
        result << view.entity(business: @business) unless view.nil?
      end
    end
    result
  end

  def find_product_type_suggestions(product_type_ids)
    exclude_products_filter = get_exclude_products_filters
    result = []
    product_type_ids.each do |product_type_id|
      type_filters = get_product_type_filters(product_type_id)
      response = if @variant.present?
                   uri = "/api/v2/supplier/#{@variant.supplier.id}/product_groupings?per_page=1&sort=popularity&sort_direction=desc&#{type_filters}"
                   uri += "&#{exclude_products_filter.join('&')}" if exclude_products_filter
                   LambdaEndpointsService.call_lambda(uri, @auth_header)
                 end
      if response.nil? || response['product_groupings'].empty?
        if @params[:supplier_ids]
          uri = "/api/v2/supplier/#{@params[:supplier_ids].join(',')}/product_groupings?per_page=1&sort=popularity&sort_direction=desc&#{type_filters}"
          uri += "&#{exclude_products_filter.join('&')}" if exclude_products_filter
          response = LambdaEndpointsService.call_lambda(uri, @auth_header)
          next if response.nil? || response['product_groupings'].empty?

          view = ProductGroupingStoreView.retrieve_with_variants([response['product_groupings'][0]['id']], response['product_groupings'][0]['variants'][0]['supplier_id']).first
          result << view.entity(business: @business) unless view.nil?
        end
      else
        view = ProductGroupingStoreView.retrieve_with_variants([response['product_groupings'][0]['id']], response['product_groupings'][0]['variants'][0]['supplier_id']).first
        result << view.entity(business: @business) unless view.nil?
      end
    end
    result
  end

  def get_exclude_products_filters
    exclude_products_filter = []
    if @cart_products
      products_to_exclude = @cart_products.map(&:id)
      exclude_products_filter = products_to_exclude.map { |id| "excludeIds%5B%5D=#{id}" }
    end
    exclude_products_filter
  end

  def get_product_type_filters(product_type_id)
    pt = ProductType.find product_type_id
    if pt.parent.nil?
      "hierarchy_category%5B%5D=#{pt.permalink}"
    elsif pt.parent&.parent.nil?
      "hierarchy_category%5B%5D=#{pt.parent.permalink}&hierarchy_type%5B%5D=#{pt.permalink}"
    else
      "hierarchy_category%5B%5D=#{pt.parent.parent.permalink}&hierarchy_type%5B%5D=#{pt.parent.permalink}&hierarchy_subtype%5B%5D=#{pt.permalink}"
    end
  end

  def find_bundle
    return Bundle.active.where(cocktail_id: @cocktail_id).first if @cocktail_id

    bundle = find_product_grouping_bundle
    bundle ||= find_brand_bundle unless @bundle
    bundle ||= find_product_type_bundle unless @bundle
    bundle
  end

  def find_product_grouping_bundle
    return unless @variant&.product_size_grouping

    Bundle.active.for_type_and_ids('ProductSizeGrouping', @variant.product_size_grouping.id).order(cocktail_id: :desc).first
  end

  def find_brand_bundle
    return unless @variant&.brand

    Bundle.active.for_type_and_ids('Brand', @variant.brand.id).order(cocktail_id: :desc).first
  end

  def find_product_type_bundle
    return unless @variant&.product_type

    Bundle.active.for_type_and_ids('ProductType', @variant.product_type.id).order(cocktail_id: :desc).first
  end
end
