class AdminAPIV1::ActivationEndpoint < BaseAPIV1
  namespace :activations do
    get do
      @products = Product.pending
                         .with_stock
                         .where.not(volume_value: nil)
                         .where.not(volume_unit: nil)
                         .where(hierarchy_category_id: ProductType.roots.where(name: %w[wine liquor beer]).select(:id))
                         .limit(10)
                         .order('RANDOM()')

      present :products, @products, with: AdminAPIV1::Entities::ActivationHit
    end
  end
  namespace :activation do
    route_param :product_id do
      before do
        @product = Product.find_by(id: params[:product_id])
        error!('Product not found', 404) if @product.nil?
      end
      namespace :actions do
        params do
          requires :product_id, type: Integer
        end
        post :accept do
          @product.activate

          status 200
          present :success, true
        end
      end
    end
  end
end
