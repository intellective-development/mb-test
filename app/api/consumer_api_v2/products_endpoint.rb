class ConsumerAPIV2::ProductsEndpoint < BaseAPIV2
  helpers Shared::Helpers::AddressHelpers
  helpers Shared::Helpers::AddressParamHelpers
  helpers Shared::Helpers::BrowseParamHelpers

  desc 'ElasticSearch backed query for products, grouped by supplier', ConsumerAPIV2::DOC_AUTH_HEADER
  params do
    use :product_searching_v1
    use :location
  end
  before do
    complete_address
  end
  get :products do
    address = get_address(required: true)
    error! 'Address not found.', 500 if address.nil?

    ls = LocationServices.new(address, select_multiple_suppliers: true)

    suppliers = ls.find_suppliers(storefront)

    params[:supplier_ids] = suppliers.map(&:id)
    params[:product_ids] = Product.parse_product_ids(params[:product_ids])

    searcher = VariantSearchService.new(params)
    results = searcher.search

    present :results, results.group_by(&:supplier_id).to_a, with: ConsumerAPIV2::Entities::VariantGroupedBySupplier
  end

  desc 'Checks availability of a given product for an address.', ConsumerAPIV2::DOC_AUTH_HEADER
  params do
    use :location
    optional :product_id, type: String,   allow_blank: false,   desc: 'Minibar Product ID for item'
    optional :upc,        type: String,   regexp: /^(\d){12}/,  desc: 'UPC code for the item'
    optional :product_grouping_id, type: String, allow_blank: false, desc: 'ID or Permalink for product grouping.'
    exactly_one_of :product_id, :upc, :product_grouping_id
  end
  after_validation do
    complete_address

    error!('No location provided.', 400) unless params[:address_id].present? || params[:coords].present? || params[:address].present?

    @address = Address.create_from_params(params)
    error! 'Address not found.', 500 if @address.nil?

    @address.geocode! unless @address.geocoded?
    error! 'Could not Geocode Address.', 500 unless @address.geocodable?

    error! 'Address is not a shipping address.', 500 unless @address.shipping?

    if params[:product_grouping_id].present?
      @product_grouping = begin
        ProductSizeGrouping.active.find(params[:product_grouping_id])
      rescue StandardError
        nil
      end

      error!('Product Grouping Not Found', 404) if @product_grouping.nil?
    else
      @product = if params[:product_id].present?
                   begin
                     Product.active.find(params[:product_id])
                   rescue StandardError
                     nil
                   end
                 elsif params[:upc].present?
                   Product.active.find_by(upc: DataCleaners::Parser::Upc.parse(params[:upc]))
                 end
      error!('Product Not Found', 404) if @product.nil?
    end
    @supplier_ids = params[:supplier_ids] if params[:supplier_ids].present?
  end
  post :check_product_availability do
    if @product
      ls = LocationServices.new(@address, product_ids: @product.id, supplier_ids: @supplier_ids || ProductSizeGrouping.supplied_by([@product.product_grouping_id]))
      suppliers = ls.find_suppliers(storefront)

      variant = @product.variants.active.available.find_by(supplier_id: suppliers.pluck(:id))

      present :product, variant&.variant_store_view
      present :supplier, variant&.supplier || suppliers&.first, with: ConsumerAPIV2::Entities::Supplier, address: @address, shipping_methods: ls.shipping_methods
      present :available, !variant.nil?
    else
      ls = LocationServices.new(@address, product_grouping_ids: @product_grouping.id, supplier_ids: @supplier_ids || ProductSizeGrouping.supplied_by([@product_grouping.id]))
      suppliers = ls.find_suppliers(storefront)

      present :product_grouping, @product_grouping.get_entity(storefront.business, nil, @supplier_ids ? @supplier_ids.compact : [suppliers&.first&.id].compact)
      present :supplier, suppliers&.first, with: ConsumerAPIV2::Entities::Supplier, address: @address, shipping_methods: ls.shipping_methods
      present :available, suppliers.any?
    end

    status 200
  end
end
