class SupplierAPIV2::VariantsEndpoint < BaseAPIV2
  helpers do
    params :pagination do
      optional :page, type: Integer
      optional :per_page, type: Integer
    end

    params :sorting do
      optional :sort_column, type: String
      optional :sort_direction, type: Symbol, values: %i[asc desc], default: :asc
    end

    params :search do
      optional :query, type: String
    end

    def resolve(names)
      return [] if names.blank?

      names.split(',').map { |v| "%#{v.downcase}%" }.join(',')
    end

    def get_products_json(products)
      searchkick_product_ids = products.map(&:id)
      Product.includes(:product_size_grouping, :variants).where(id: searchkick_product_ids)
    end
  end

  namespace :products do
    params do
      use :pagination
      use :sorting
      use :search
      optional :in_stock, type: Boolean
    end
    desc 'Load a list of products sold by the current supplier.'
    get do
      variants, total_count, total_pages = SupplierVariantSearchService.new(current_supplier, params).search(params)

      header 'X-Total', total_count
      header 'X-Total-Pages', total_pages
      present variants, with: SupplierAPIV2::Entities::Variant, current_supplier: current_supplier
    end

    desc 'Batch check if variants exist through name'
    params do
      requires :variant_names, type: String
      requires :supplier_id, type: Integer
    end
    before { @product_names = resolve(params[:variant_names]) }

    post :existing do
      current_supplier
      products = Variant.supplier_variants_by_names(params[:supplier_id], @product_names)
      present products, with: SupplierAPIV2::Entities::Variant
    end

    desc 'Search by products'
    get :search do
      filters = {}
      filters[:state] = { not: %w[merged inactive] }
      filters[:variant_count] = { gt: 0 }

      products =
        Product.search(
          params[:query].presence || '*',
          where: filters,
          limit: 50,
          order: [{ 'merged_count': :desc }]
        )
      present get_products_json(products), with: SupplierAPIV2::Entities::ProductSearch
    end
  end
end
