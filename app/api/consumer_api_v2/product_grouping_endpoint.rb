class ConsumerAPIV2::ProductGroupingEndpoint < BaseAPIV2
  helpers Shared::Helpers::AddressHelpers
  helpers Shared::Helpers::AddressParamHelpers
  helpers Shared::Helpers::BrowseParamHelpers
  helpers Shared::Helpers::SupplierHelpers
  helpers Shared::Helpers::FacetParamHelpers

  helpers do
    def short_query?
      params[:query].length < 3 && params[:query] != '*'
    end
  end

  SPONSORED_COUNT = 3

  # TODO: We should think about the naming of these endpoints - they have each been built in isolation to address
  #       specific use-cases which may not be obvious given their naming.
  #
  #       1. /product_groupings returns product groupings, grouped by supplier, used by iOS search switching.
  #          (suggest changing to... something, or parameterizing the grouping behavior).
  #       2. /product_grouping returns a single product grouping (suggest change to /product).
  #       3. /products returns product groupings, agnostic of supplier.
  desc 'Product Grouping browsing endpoint, intended for external PLP browsing (no suppliers)', ConsumerAPIV2::DOC_AUTH_HEADER
  params do
    use :product_external
  end
  get :products do
    # This endpoint currently only supports Brand PLP's, hence we are able to skip Elasticsearch
    # and query the view directly (hence why we need to fetch ids then do a second query).
    # Ultimately as we flesh out external PLP use-cases and as the requirements evolve (e.g.
    # popularity sorting) then we will likely want to adjust our approach.
    #
    # Note: We are returning child brands in addition to the provided brand_id (see the `coerce_with`
    #       where we define the `:product_external` parameter block).
    product_grouping_ids = ProductGroupingExternalProductView.where(brand_id: params[:brand])
                                                             .select(:product_grouping_id, :permalink)
                                                             .order(popularity: :desc, featured: :desc)
                                                             .map(&:product_grouping_id)
                                                             .uniq

    paginated_ids = Kaminari.paginate_array(product_grouping_ids)
                            .page(params[:page])
                            .per(params[:per_page])

    present :product_groupings, ProductGroupingStoreView.retrieve_with_products(paginated_ids), with: ProductGroupingStoreView::Entity, exclude_variants: true, include_products: true
    present :facets, []
    present :promotions, []
    present :count, product_grouping_ids.length
  end

  desc 'ElasticSearch backed query for product groupings, grouped by supplier', ConsumerAPIV2::DOC_AUTH_HEADER
  params do
    use :location
  end
  before do
    complete_address
  end
  get :product_groupings do
    if short_query?
      # iOS will send queries for single words
      present :results, {}
    else
      unless params[:supplier_ids]
        address = get_address(required: true)
        error! 'Address not found.', 404 if address.nil?

        ls = LocationServices.new(address, select_multiple_suppliers: true)
        suppliers = ls.find_suppliers(storefront)

        params[:supplier_ids] = suppliers.map(&:id)
      end

      Rails.logger.info "ProductGroupingSearch by location on Rails --> #{request.params.to_query}"

      uri = "/api/v2/supplier/#{params[:supplier_ids].join(',')}/product_groupings?per_page=5&#{request.params.to_query}"
      response = LambdaEndpointsService.call_lambda(uri, request.headers['Authorization'])

      present :results, ProductSizeGrouping.get_views_from_es_result(response, params[:supplier_ids]).group_by(&:first_supplier_id).to_a, with: ConsumerAPIV2::Entities::ProductGroupingGroupedBySupplier, business: storefront.business
    end
  end

  resource :product_grouping do
    desc 'Returns a single Product Grouping Entity given a Product Grouping ID', ConsumerAPIV2::DOC_AUTH_HEADER
    route_param :product_grouping_identifier do
      get do
        product_grouping = ProductSizeGrouping.find_by_identifier(params[:product_grouping_identifier])
        product_grouping_entity = product_grouping.get_external_entity if product_grouping.present?

        # TODO: Consider making this a 404
        error!({ name: 'ProductGroupingUnavailable', message: 'Product not found.' }, 404) unless product_grouping.present? && product_grouping_entity

        present product_grouping_entity
      end
    end
  end

  resource :supplier do
    after_validation do
      load_suppliers
    end
    desc 'ElasticSearch backed query interface for a supplier\'s product groupings', ConsumerAPIV2::DOC_AUTH_HEADER
    route_param :supplier_id do
      get :product_groupings do
        Rails.logger.info "ProductGroupingSearch on Rails --> #{request.params.to_query}"

        uri = "#{request.path}?#{request.params.to_query}"

        present LambdaEndpointsService.call_lambda(uri, request.headers['Authorization'])
      end
    end

    desc 'ElasticSearch backed query interface for returning product counts only.', ConsumerAPIV2::DOC_AUTH_HEADER
    route_param :supplier_id do
      get :counts do
        Rails.logger.info "ProductGroupingSearch count on Rails --> #{request.params.to_query}"

        uri = "#{request.path}?#{request.params.to_query}"
        response = LambdaEndpointsService.call_lambda(uri, request.headers['Authorization'])

        present response
      end
    end

    desc 'ElasticSearch backed query interface for returning recommended products', ConsumerAPIV2::DOC_AUTH_HEADER
    params do
      use :related_products
    end
    route_param :supplier_id do
      get :related do
        params[:supplier_ids] = @supplier_ids
        params[:product_grouping_ids] = Array(params[:product_grouping_id])

        searcher = ProductGroupingSearch::FeaturedProducts.new(params, @user)
        views = filter_results(searcher.search, @supplier_ids).sample(params[:count] || 8)

        present :product_groupings, views, with: ConsumerAPIV2::Entities::ElasticSearchProductGrouping, platform: client_details.platform
        present :count, views.length
      end
    end

    desc 'Get single product grouping for a given supplier', ConsumerAPIV2::DOC_AUTH_HEADER
    route_param :supplier_id do
      resource :product_grouping do
        route_param :product_grouping_identifier do
          get do
            product_grouping = ProductSizeGrouping.find_by_identifier(params[:product_grouping_identifier])

            supplier_ids = @supplier_ids
            max_suppliers = params[:max_suppliers]

            if max_suppliers.present? && product_grouping.present?
              supplier_ids &= product_grouping.suppliers.map(&:id)
              supplier_ids = supplier_ids
                             .uniq
                             .first(max_suppliers.to_i)
            end

            product_grouping_entity = product_grouping.get_entity(storefront.business, nil, supplier_ids) if product_grouping.present?

            # TODO: Consider making this a 404
            error!({ name: 'ProductGroupingUnavailable', message: 'Product not found.' }, 404) unless product_grouping.present? && product_grouping_entity

            present product_grouping_entity
          end
        end
      end
    end
  end

  helpers do
    def calc_sort_weight(value)
      1000 / (value.to_f + 1) + 20
    end

    def filter_results(results, supplier_ids)
      results.each do |result|
        variants = []
        # Get only matched variants
        # result.inner_hits.each do |inner|
        #   # 0 is the string variants and 1 is the array of variants.
        #   inner[1].hits.hits.each do |hit|
        #     variants << hit._source
        #   end
        # end
        if result['inner_hits'].present?
          result['inner_hits']['variants']['hits']['hits'].each do |hit|
            variants << hit['_source']
          end
        else
          result['variants'].each do |variant|
            # on nested_filter we get only the first 100 matches on inner_hits
            next if variants.size == 100

            variants << variant if supplier_ids.include?(variant.supplier_id) && variant.active == true && variant.in_stock.positive?
          end
        end

        # avoid errors when external_products and deals are not set yet
        result['external_products'] = result['external_products'] || []
        result['deals'] = result['deals'] || []

        # order variants
        result['variants'] = variants.sort_by do |variant|
          [ProductPriorityScope::VOLUME_ORDER.include?(variant['short_volume']) ? ProductPriorityScope::VOLUME_ORDER.index(variant['short_volume']) : calc_sort_weight(variant['short_volume']), ProductPriorityScope::PACK_SIZE_ORDER.include?(variant['short_pack_size']) ? ProductPriorityScope::PACK_SIZE_ORDER.index(variant['short_pack_size']) : calc_sort_weight(variant['short_pack_size']), variant['price']]
        end

        # order external_products
        result['external_products'] = result['external_products'].sort_by do |external_product|
          [ProductPriorityScope::VOLUME_ORDER.include?(external_product['short_volume']) ? ProductPriorityScope::VOLUME_ORDER.index(external_product['short_volume']) : calc_sort_weight(external_product['short_volume']), ProductPriorityScope::PACK_SIZE_ORDER.include?(external_product['short_pack_size']) ? ProductPriorityScope::PACK_SIZE_ORDER.index(external_product['short_pack_size']) : calc_sort_weight(external_product['short_pack_size'])]
        end

        result['supplier_id'] = result['variants'][0]['supplier_id'] if result['variants'].present? && result['variants'][0].present?
        # filter deals
        free_shipping_deal = false
        result['deals'] = result['deals'].select do |deal|
          valid_deal = Date.parse(deal['starts_at']).past? && !Date.parse(deal['ends_at']).past?
          # we want to return only 1 FreeShipping deal
          if valid_deal && deal['type'] == 'FreeShipping'
            if !free_shipping_deal
              free_shipping_deal = true
            else
              valid_deal = false
            end
          end
          valid_deal
        end

        # filter variant deals
        result['variants'].each do |variant|
          volume_discount_deal = false

          # avoid errors when deals are not set yet
          variant['deals'] = variant['deals'] || []

          variant['deals'] = variant['deals'].select do |deal|
            valid_deal = Date.parse(deal['starts_at']).past? && !Date.parse(deal['ends_at']).past?
            # we want to return only 1 VolumeDiscount deal
            if valid_deal && deal['type'] == 'VolumeDiscount'
              if !volume_discount_deal
                volume_discount_deal = true
              else
                valid_deal = false
              end
            end
            valid_deal
          end
        end
      end
      results.reject { |result| result['variants'].empty? }
    end
  end
end
