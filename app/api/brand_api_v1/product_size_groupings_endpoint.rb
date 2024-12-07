class BrandAPIV1::ProductSizeGroupingsEndpoint < BaseAPIV1
  helpers do
    params :pagination do
      optional :page, type: Integer, default: 1
      optional :per_page, type: Integer, default: 20
    end
  end

  namespace :product_size_groupings do
    params do
      use :pagination
    end
    desc 'Paginated endpoint to return product groupings belonging to a brand'
    get do
      # rubocop:disable Layout/MultilineMethodCallIndentation
      product_groupings = current_brands_product_groupings
        .includes(:product_properties, :product_content, :hierarchy_subtype, :hierarchy_type, :hierarchy_category, :brand, :products)
        .active
        .order(:name)
        .page(params[:page])
        .per(params[:per_page])
      # rubocop:enable Layout/MultilineMethodCallIndentation

      header 'X-Total', product_groupings.total_count.to_s
      header 'X-Total-Pages', product_groupings.total_pages.to_s

      present product_groupings, with: BrandAPIV1::Entities::ProductSizeGrouping
    end
  end
end
