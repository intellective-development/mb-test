class PartnerAPIV1::ProductsEndpoint < PartnerAPIV1
  namespace :products do
    desc 'Search through all products by brand or product name', BaseAPI::DOC_AUTH_ONLY_HEADER
    params do
      optional :id, type: Integer, desc: 'Product ID'
      optional :brand, type: String, desc: 'Brand Name'
      optional :name, type: String, desc: 'Product Name'
      optional :upc, type: String, desc: 'UPC code for the product'
      optional :item_volume, type: String, desc: 'Product item_volume'
      optional :category, type: String, desc: 'Product category'
      optional :type, type: String, desc: 'Product type'
      optional :subtype, type: String, desc: 'Product subtype'

      optional :page, type: Integer, default: 1, desc: 'Page number'
      optional :per_page, type: Integer, default: 20, values: 1..100, desc: 'Products per page'
      at_least_one_of :id, :brand, :name, :upc, :item_volume, :category, :type, :subtype
    end
    get do
      filters = { active: true }

      filters[:name]        = { like: "%#{params[:name]}%" } if params[:name].present?
      filters[:brand]       = { like: "%#{params[:brand]}%" } if params[:brand].present?
      filters[:item_volume] = { like: "%#{params[:item_volume]}%" } if params[:item_volume].present?
      filters[:id]          = params[:id] if params[:id].present?
      filters[:category]    = params[:category] if params[:category].present?
      filters[:type]        = params[:type] if params[:type].present?
      filters[:subtype]     = params[:subtype] if params[:subtype].present?
      filters[:upc]         = params[:upc] if params[:upc].present?

      product_search = {
        where: filters,
        limit: params[:per_page],
        page: params[:page]
      }

      present Product.search('*', product_search), with: PartnerAPIV1::Entities::Product
    end
  end
end
