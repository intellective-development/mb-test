class AdminAPIV1::ProductSizeGroupingsEndpoint < BaseAPIV1
  namespace :product_size_groupings do
    # desc 'Create a product size grouping'
    # params do
    #  requires :name
    #  requires :brand_id
    # end
    # post do
    #  @group = ProductSizeGrouping.new(group_from_params(params))
    #  @group.save!

    #  present @group, with: Shared::Entities::ProductSizeGrouping
    # end

    desc 'search product groupings'
    get do
      query = params[:query].presence || '*'
      params[:state] ||= 'active'

      @groupings = ProductSizeGrouping.search(
        query,
        fields: ['name'],
        includes: %i[images product_type],
        where: { active: true },
        order: { name: :asc },
        per_page: 20,
        page: 1
      )
      present @groupings, with: AdminAPIV1::Entities::Query::ProductGrouping
    end

    route_param :grouping_id do
      before do
        @group = ProductSizeGrouping.find_by(id: params[:grouping_id])
        error!('Product Size Grouping not found', 404) if @group.nil?
      end

      desc 'get product size group by id'
      get do
        present @group, with: Shared::Entities::ProductSizeGrouping
      end

      desc 'update product size group by id'
      put do
        @group.update(group_from_params(params))
        @group.save!

        present @group, with: Shared::Entities::ProductSizeGrouping
      end

      # desc 'delete product size group by id'
      # delete do
      #  @group.destroy!
      #  present @group, with: Shared::Entities::ProductSizeGrouping
      # end
    end
  end

  helpers do
    def group_from_params(params)
      params.except(:grouping_id, :id, :featured, :searchable, :state, :product_content_id, :hierarchy_category_id, :hierarchy_subtype_id, :hierarchy_type_id, :product_type_id, :meta_description, :meta_keywords, :description, :permalink, :keywords, :created_at, :updated_at, :tax_category_id, :trimmed_name)
    end
  end
end
