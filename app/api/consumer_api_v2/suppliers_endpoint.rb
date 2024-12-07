class ConsumerAPIV2::SuppliersEndpoint < BaseAPIV2
  helpers Shared::Helpers::AddressHelpers
  helpers Shared::Helpers::AddressParamHelpers
  helpers Shared::Helpers::BrowseParamHelpers
  helpers Shared::Helpers::SupplierHelpers

  helpers do
    def platform
      user_agent = String(headers['User-Agent']).downcase
      if user_agent match?(/minibarapp/)
        'android'
      elsif user_agent match?(/iphone|cfnetwork|darwin/)
        user_agent match?(/minibar/) ? 'iphone' : 'web'
      elsif user_agent match?(/ipad/)
        user_agent martch?(/minibar/) ? 'ipad' : 'web'
      else
        'web'
      end
    end
  end

  format :json
  desc 'Checks supplier availability for given address, returning an array of suppliers.', ConsumerAPIV2::DOC_AUTH_HEADER
  params do
    use :location
    optional :routing_options, type: Hash do
      optional :defer_load,                type: Boolean, default: false, desc: 'opts in to deferred loading behaviors when routing'
      optional :preferred_supplier_ids,    type: Array,   default: [],    desc: 'prefer to route to these suppliers'
      optional :product_grouping_ids,      type: Array,   default: [],    desc: 'suppliers who carry these will be prioritized'
      optional :product_ids,               type: Array,   default: [],    desc: 'suppliers who carry these will be prioritized'
      optional :select_multiple_suppliers, type: Boolean, default: false, desc: 'select all suppliers for an address'
      optional :supplier_ids,              type: Array,   default: [],    desc: 'restrict routing to these suppliers'
      optional :region_id,                 type: String,  default: nil,   desc: "Google's region_id, in case customer comes from there"
      optional :liquid_checkout,           type: Boolean, default: false, desc: 'If true, it will use expanded logic to allow LCO ship coverage'
    end
    optional :data, type: Hash do
      optional :email, type: String
    end
  end
  before do
    complete_address
  end
  get :suppliers do
    if params[:region_id].present? && (google_region = GoogleRegion.find_by_region_id(params[:region_id]))
      # If region_id is present we'll always overwrite address
      params[:address] = google_region.default_address
      # we want to return all available suppliers now
      # params[:shipped_only] = true
    end

    address = get_address(required: true)

    error! 'Address not found.', 500 if address.nil?
    error! 'Address is not a shipping address.', 500 unless address.shipping?

    email = params.dig(:data, :email)
    if email
      ZipcodeWaitlist.find_or_create_by(
        email: email,
        zipcode: address.zip_code,
        source: ZipcodeWaitlist::ADDRESS_ENTRY_SOURCE,
        doorkeeper_application: doorkeeper_application
      )
    end

    location_options = {}
    # FIXME: Adding feature flag to deferred loading due to issue relating to store business versions
    #        being revved - this can be removed when feature is fully spported by web store.
    location_options[:defer_load]                = Feature[:deferred_loading].enabled? && params.dig('routing_options', 'defer_load')
    location_options[:dynamic_routing]           = Feature[:dynamic_routing].enabled?
    location_options[:preferred_supplier_ids]    = params.dig('routing_options', 'preferred_supplier_ids')
    location_options[:select_multiple_suppliers] = params.dig('routing_options', 'select_multiple_suppliers')
    location_options[:supplier_ids]              = params.dig('routing_options', 'supplier_ids')

    if params.dig('routing_options', 'product_ids')
      # client could be sending permalinks, this ensures we're getting (valid) ids
      location_options[:product_ids] = Product.where_identifier(params.dig('routing_options', 'product_ids')).pluck(:id)
    end

    location_options[:product_grouping_ids] = ProductSizeGrouping.where_identifier(params.dig('routing_options', 'product_grouping_ids')).pluck(:id) if params.dig('routing_options', 'product_grouping_ids')
    location_options[:include_digital_delivery] = true
    location_options[:shipped_only] = params[:shipped_only]

    ls = LocationServices.new(address, location_options)
    suppliers = ls.find_suppliers(storefront)

    error! 'No suppliers found.', 404 if suppliers.empty? && !ls.deferrable_present

    present :suppliers, suppliers, with: ConsumerAPIV2::Entities::Supplier, shipping_methods: ls.shipping_methods, alternative_suppliers: [], customer_address: address
    present :deferrable_present, ls.deferrable_present
  end

  resource :supplier do
    after_validation do
      load_suppliers
    end

    desc 'Returns supplier object.', ConsumerAPIV2::DOC_AUTH_HEADER
    params do
      requires :supplier_id, type: String, desc: 'Supplier ID.'
    end
    route_param :supplier_id do
      params do
        use :location
      end
      before do
        complete_address
      end
      get do
        # TODO: This endpoint is hit fairly frequently (heartbeat) - we may wish
        #       to think about re-enabling server side caching, as long as it is unique
        #       per user (since shipping methods vary by address)
        # TODO: Do we want to consider a non-200 response if the client is requesting
        #       a supplier which does not delivery to their address?
        address = get_address(required: true)

        ls = LocationServices.new(address, include_digital_delivery: true)

        present ConsumerAPIV2::Entities::Supplier.represent(@suppliers.size > 1 ? @suppliers : @supplier,
                                                            shipping_methods: ls.shipping_methods,
                                                            alternative_suppliers: ls.alternative_suppliers(storefront),
                                                            customer_address: address)
      end
    end

    desc 'Query available product categories for a given supplier', ConsumerAPIV2::DOC_AUTH_HEADER
    params do
      requires :supplier_ids, type: Array, desc: 'Supplier ID(s)', coerce_with: ->(val) { val.split(',') }
      requires :query, type: String, allow_blank: false, desc: 'Search term', coerce_with: ->(val) { val.slice(0, 255) }
    end
    route_param :supplier_ids do
      get :product_types do
        if params[:query].length < 3
          matches = {}
        else
          product_type_ids = SupplierProfile.where(supplier_id: params[:supplier_ids])
                                            .flat_map(&:product_type_ids)
                                            .uniq
                                            .sort

          matches = ProductType.active
                               .where(id: product_type_ids)
                               .where("lower(name) like '%#{String(params[:query]).downcase.delete("'")}%'")
                               .order(:name)
                               .limit(5)
        end

        present :product_types, matches, with: ConsumerAPIV2::Entities::Search::ProductType
      end
    end

    desc 'Elastic Search backed query interface for a supplier', ConsumerAPIV2::DOC_AUTH_HEADER
    params do
      use :product_searching_v1
    end
    before do
      # [TECH-1978]
      if params[:product_ids]
        @product_id_permalink_map = {}
        params[:product_ids].each do |identifier|
          id = Product.parse_product_id(identifier)
          @product_id_permalink_map[id] = identifier
        end
      end
    end
    route_param :supplier_id do
      get :products do
        params[:supplier_ids] = @supplier_ids
        searcher = VariantSearchService.new(params)
        results = searcher.search

        promotions = []
        if params[:page] == 1
          promotions = Personalization.get_plp_promotions(@suppliers.map(&:id), {
                                                            search: params[:query],
                                                            tag: params[:tag],
                                                            type: params[:type].to_s
                                                          },
                                                          String(platform).include?('web'),
                                                          client_details.platform == 'android' || platform == 'ipad' || params[:page] > 1)
        end

        # [TECH-1978] Send back requested permalink
        if @product_id_permalink_map
          searcher.get_views.each do |product|
            requested_permalink = @product_id_permalink_map[product.product_id]
            product.permalink = requested_permalink if requested_permalink
          end
        end

        present :products,   searcher.get_views
        present :count,      results.total_count
        present :facets, results.aggs.to_a, with: ConsumerAPIV2::Entities::Facet, type: params[:category]
        present :promotions, promotions, with: ConsumerAPIV2::Entities::Promotion
      end
    end

    params do
      requires :supplier_id, type: String, desc: 'Supplier ID.'
      optional :sku, type: String, desc: 'Variant SKU'
      optional :id, type: String, desc: 'Variant ID'
    end
    route_param :supplier_id do
      resource :product do
        route_param :product_id do
          get do
            variant = nil

            # Is the product ID being passed as a permalink?
            if /[a-z]/.match?(params[:product_id])
              product = begin
                Product.find(params[:product_id])
              rescue StandardError
                nil
              end
              variant = product ? product.variants.active.available.where(supplier_id: @supplier_ids).first : nil
            else
              @suppliers.each do |supplier|
                variant = supplier.variants.active.includes(product: [product_properties: [:property]]).find_by(id: params[:product_id]) if variant.nil?
              end
            end
            error!({ name: 'ProductUnavailable', message: 'Product not found.' }, 400) if variant.nil?

            present variant.variant_store_view
          end
        end
      end
      get :product do
        variant = params[:id].blank? ? @supplier.variants.active.find_by(sku: params[:sku]) : @supplier.variants.active.find_by(id: params[:id])
        error!({ name: 'ProductUnavailable', message: 'Product not found.' }, 400) if variant.nil?

        present variant.variant_store_view
      end
    end

    desc 'Returns variants for a given supplier based on a set of variant ids', ConsumerAPIV2::DOC_AUTH_HEADER
    params do
      requires :supplier_id, type: String, desc: 'Supplier ID.'
      requires :product_id, type: String, desc: 'Array of IDs'
      optional :include_product_grouping, type: Boolean, default: false, desc: 'Determines if new entity is used.'
    end
    route_param :supplier_id do
      namespace :alternatives do
        route_param :product_id do
          get do
            alternatives = params[:product_id].split(',').map do |variant_id|
              variant = Variant.active.find_by(id: variant_id)
              {
                request_id: variant_id,
                variant: variant ? variant.siblings.active.available.find_by(supplier_id: params[:supplier_id]) : nil
              }
            end
            entity = params[:include_product_grouping] ? ConsumerAPIV2::Entities::Alternative : ConsumerAPIV2::Entities::AlternativeNoGrouping
            present :alternatives, alternatives, with: entity
          end
        end
      end
    end

    desc 'Returns a supplier for a given permalink', ConsumerAPIV2::DOC_AUTH_HEADER
    params do
      requires :actual_permalink, type: String, desc: 'Supplier permalink.'
    end
    resource :permalink do
      route_param :actual_permalink do
        get do
          supplier = Supplier.active.includes(:address, :shipping_methods, :delivery_hours).find_by(permalink: params[:actual_permalink])
          error! 'Supplier not found.', 404 if supplier.nil?
          present supplier, with: ConsumerAPIV2::Entities::Supplier, shipping_methods: supplier.shipping_methods, delivery_hours: supplier.delivery_hours
        end
      end
    end
  end
end
