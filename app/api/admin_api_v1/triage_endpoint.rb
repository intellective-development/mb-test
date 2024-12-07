class AdminAPIV1::TriageEndpoint < BaseAPIV1
  namespace :triage do
    desc 'Elastic Search backed query interface for retrieving candidates for product triage tool'

    params do
      requires :page, type: Integer, desc: '', default: 1
    end
    namespace :products do
      get do
        filters = {
          state: ['pending'],
          item_volume: { not: ['', nil] },
          category: { not: [nil, 'unknown'] },
          type: { not: nil }
        }

        @products = Product.search('*',
                                   where: filters,
                                   boost_by: { variant_count: { factor: 100 } },
                                   boost_where: {
                                     in_stock: { value: true, factor: 2000 },
                                     type: { value: { not: nil }, factor: 1500 },
                                     sub_type: { value: { not: nil }, factor: 800 },
                                     has_image: { value: true, factor: 5000 }
                                   },
                                   limit: 10,
                                   page: @params[:page])

        present :products, @products, with: AdminAPIV1::Entities::Triage::Product
      end
    end
    namespace :product do
      route_param :product_id do
        before do
          @product = Product.find_by(id: params[:product_id])
          error!('Product not found', 404) if @product.nil?
        end

        after do
          status 200
          present :success, true
        end

        namespace :action do
          params do
            requires :product_id, type: Integer
          end
          post :activate do
            @product.activate
          end
          post :deactivate do
            @product.deactivate
          end
          post :flag do
            @product.flag
          end
          post :pend do
            @product.pend
          end
        end
      end
    end
  end
end
