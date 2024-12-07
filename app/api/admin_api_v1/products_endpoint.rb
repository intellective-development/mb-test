class AdminAPIV1::ProductsEndpoint < BaseAPIV1
  namespace :products do
    desc 'Search products'
    params do
      optional :query, type: String
    end
    get do
      query = params[:query].presence || '*'

      products = Product.search(
        query,
        fields: %i[id name],
        where: { state: 'active' },
        includes: [:hierarchy_category, { product_size_grouping: [:hierarchy_category] }],
        order: { name: :asc },
        per_page: 20,
        page: 1
      )

      present :products, products, with: AdminAPIV1::Entities::Query::ProductEntity
    end

    get :pending do
      @products = Product.pending
                         .joins(:product_size_grouping)
                         .where.not(product_type_id: ProductType.roots.pluck(:id))
                         .where.not(volume_value: nil, volume_unit: nil)
                         .order('random()')
                         .limit(10)
                         .includes(:images, :brand, :prototype, :active_variants, product_properties: [:property], product_type: [:parent])

      present :products, @products, with: AdminAPIV1::Entities::Product
    end
    get :imageless do
      @products = Product.active_or_pending
                         .where(images: { imageable_id: nil, imageable_type: 'Product' })
                         .order('random()')
                         .limit(10)
                         .includes(:images, :brand, :prototype, :active_variants, product_properties: [:property], product_type: [:parent])

      present :products, @products, with: AdminAPIV1::Entities::Product
    end
  end
  namespace :product do
    route_param :product_id do
      before do
        @product = Product.find_by(id: params[:product_id])
        error!('Product not found', 404) if @product.nil?
      end
      namespace :actions do
        params do
          requires :product_id, type: Integer
        end
        post :activate do
          error!('Product is not pending.', 400) unless @product.pending?
          @product.activate
          status 200
          present :success, true
        end
        params do
          requires :product_id, type: Integer
          requires :url, type: String
        end
        post :add_image do
          @product.images << Image.new(photo_from_link: product[:url])
          status 200
          present :success, true
        end
        params do
          requires :product_id, type: Integer
        end
        post :flag do
          error!('Product is already flagged.', 400) if @product.flagged?
          @product.flag
          status 200
          present :success, true
        end
      end
    end
  end
end
