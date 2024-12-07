class AdminAPIV1::BrandsEndpoint < BaseAPIV1
  namespace :brands do
    desc 'get all brands'
    get do
      present paginate(Brand.all), with: Shared::Entities::Brands::Brand
    end

    desc 'search brands'
    get :search do
      present paginate(Brand.admin_grid(name: params[:q], sponsored: params[:sponsored])), with: Shared::Entities::Brands::Brand
    end

    desc 'Create a brand'
    params do
      requires :name
    end
    post do
      @brand = Brand.new(brand_from_params(params))
      compose_brand
    end

    route_param :brand_id do
      before do
        @brand = Brand.find_by(id: params[:brand_id])
        error!('Brand not found', 404) if @brand.nil?
      end

      desc 'get brand by id'
      get do
        present @brand, with: Shared::Entities::Brands::Brand
      end

      namespace :merge do
        route_param :merge_id do
          before do
            @merging = Brand.find_by(id: params[:merge_id])
            error('Merge Brand not found', 404) if @merging.nil?
          end

          get do
            groups = ProductSizeGrouping.where({ brand_id: @merging.id })
            groups.each do |group|
              group.update({ brand_id: @brand.id })
              group.save!
            end
            @merging.destroy!
            present @brand, with: Shared::Entities::Brands::Brand
          end
        end
      end

      desc 'update brand by id'
      put do
        compose_brand
      end

      desc 'delete brand by id'
      delete do
        @brand.destroy!
        present @brand, with: Shared::Entities::Brands::Brand
      end
    end
  end

  helpers do
    def compose_brand
      @brand.name = params[:name]
      @brand.id = params[:brand_id]
      @brand.save!
      present @brand, with: Shared::Entities::Brands::Brand
    end

    def brand_from_params(params)
      params.except(:brand_id)
    end
  end
end
