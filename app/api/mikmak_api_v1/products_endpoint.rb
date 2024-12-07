class MikmakAPIV1::ProductsEndpoint < BaseAPIV1
  helpers Shared::Helpers::AddressParamHelpers
  helpers do
    def authenticate!
      return false if headers['Authorization'].nil?

      error!('401 Unauthorized', 401) unless headers['Authorization'] == "Token #{ENV['MIKMAK_AUTH_TOKEN']}"
    end
  end

  namespace :products do
    desc 'Retrieves all products in stock'
    before do
      authenticate!
    end
    get do
      present paginate(Product.active), with: MikmakAPIV1::Entities::Product
    end
  end

  namespace :product_details do
    params do
      optional :product_id, type: String,   allow_blank: false,   desc: 'Minibar Product ID for item'
      optional :upc,        type: String,   regexp: /^(\d){12}/,  desc: 'UPC code for the item'
      optional :permalink,  type: String,   allow_blank: false,   desc: 'Product permalink'
      exactly_one_of :product_id, :upc, :permalink
      use :location
    end
    before do
      authenticate!
      @product = if params[:product_id].present?
                   begin
                     Product.active.find(params[:product_id])
                   rescue StandardError
                     nil
                   end
                 elsif params[:upc].present?
                   Product.active.find_by(upc: DataCleaners::Parser::Upc.parse(params[:upc]))
                 elsif params[:permalink].present?
                   Product.friendly.find(params[:permalink])
                 end
      error!('Product Not Found', 404) if @product.nil?

      @address = Address.create_from_params(params)
    end
    desc 'Retrieve product details'
    get do
      if @address
        ls = LocationServices.new(@address, product_ids: @product.id, supplier_ids: @supplier_ids || ProductSizeGrouping.supplied_by([@product.product_grouping_id]))
        suppliers = ls.find_suppliers(Storefront.find(Storefront::MINIBAR_ID))
        variant = @product.variants.active.available.find_by(supplier_id: suppliers&.first)
      end

      if @address
        present :product, variant&.variant_store_view, with: MikmakAPIV1::Entities::Variant
        present :supplier, suppliers&.first, with: ConsumerAPIV2::Entities::Supplier, address: @address, shipping_methods: ls.shipping_methods
        present :available, !variant.nil?
      else
        present :product, @product, with: MikmakAPIV1::Entities::Product
      end
    end
  end
end
