class AdminAPIV1::QueryEndpoint < BaseAPIV1
  RegionData = Struct.new(:states, :regions) do
    def initialize
      regions = Set.new
      states = State.includes(:regions).map do |state|
        regions.merge(state.regions)
        state
      end
      super(states, regions.to_a)
    end
  end

  BRAND_LIMIT = 50
  PRODUCT_TYPE_LIMIT = 50

  desc 'Query interface for retrieving brand options'
  namespace :brands do
    params do
      optional :query, type: String
      optional :brands, type: Array[String]
      optional :present_type, type: String
    end

    get do
      if params[:present_type] == 'navigation'
        brands = if params[:query]
                   Brand.matching_name(params[:query]).limit(200)
                 elsif params[:brands]
                   Brand.by_permalink(params[:brands])
                 else
                   Brand.limit(200)
                 end

        relation = brands.includes(:product_size_groupings).order(name: :ASC).select(:permalink, :name)
        present relation, with: AdminAPIV1::Entities::Query::BrandsEntity
      else
        brands_joined = Brand.joins('LEFT JOIN brands AS parents ON brands.parent_brand_id = parents.id').unknown_first.order(:name)
        brands = brands_joined.where('(unaccent(lower(brands.name)) LIKE ?) OR (unaccent(lower(parents.name)) LIKE ?)', "%#{params[:query].downcase}%", "%#{params[:query].downcase}%").limit(BRAND_LIMIT)
        present :brands, brands, with: AdminAPIV1::Entities::Query::Brand
      end
    end
  end

  desc 'Query interface for retrieving product type options'
  namespace :product_types do
    params do
      requires :query, type: String
    end
    get do
      types_joined = ProductType.joins('LEFT JOIN product_types AS parents ON product_types.parent_id = parents.id').order(:name)
      types = types_joined.where('(lower(product_types.name) LIKE ?) OR (lower(parents.name) LIKE ?)', "%#{params[:query].downcase}%", "%#{params[:query].downcase}%").limit(PRODUCT_TYPE_LIMIT)
      present :types, types, with: AdminAPIV1::Entities::Query::ProductType
    end
  end

  desc 'Query interface for retrieving supplier options'
  namespace :suppliers do
    params do
      optional :query, type: String
      optional :suppliers, type: Array[String]
      optional :present_type, type: String
    end

    get do
      if params[:present_type] == 'navigation'
        suppliers = if params[:query]
                      Supplier.matching_name(params[:query]).limit(200)
                    elsif params[:suppliers]
                      Supplier.by_permalink(params[:suppliers])
                    else
                      Supplier.limit(200)
                    end
        present suppliers.order(name: :ASC).select(:permalink, :name), with: AdminAPIV1::Entities::Query::SuppliersEntity
      else
        suppliers_joined = Supplier.includes(:region).joins('LEFT JOIN regions ON suppliers.region_id = regions.id').order(:name).limit(200)
        suppliers = suppliers_joined.where('(lower(suppliers.name) LIKE ?) OR (lower(regions.name) LIKE ?)', "%#{params[:query]}%", "%#{params[:query]}%")
        present :suppliers, suppliers, with: AdminAPIV1::Entities::Query::Supplier
      end
    end
  end

  desc 'Given sellable type and ids retrieves sellable entities'
  namespace :sellables do
    params do
      requires :sellable_type, type: String, desc: 'type of sellable entity'
      optional :sellable_ids, type: Array, desc: 'list of sellable ids to retrieve entities for'
      optional :fetch_from_coupon_id, type: Integer, desc: 'will fetch sellables from coupon'
    end
    get do
      params[:sellable_ids] = CouponItem.where(item_type: params[:sellable_type], coupon_id: params[:fetch_from_coupon_id]).pluck(:item_id) if params[:fetch_from_coupon_id]

      case params[:sellable_type]
      when 'Supplier'
        suppliers = Supplier.includes(:region).order(:name).find(params[:sellable_ids])
        present :sellables, suppliers, with: AdminAPIV1::Entities::Query::Supplier
      when 'ProductType'
        types = ProductType.includes(:parent).order(:name).find(params[:sellable_ids])
        present :sellables, types, with: AdminAPIV1::Entities::Query::ProductType
      when 'ProductGrouping'
        types = ProductSizeGrouping.order(:name).find(params[:sellable_ids])
        present :sellables, types, with: AdminAPIV1::Entities::Query::ProductGrouping
      when 'Cocktail'
        types = Cocktail.order(:name).find(params[:sellable_ids])
        present :sellables, types, with: AdminAPIV1::Entities::Query::Cocktail
      when 'Brand'
        brands = Brand.includes(:parent).order(:name).find(params[:sellable_ids])
        present :sellables, brands, with: AdminAPIV1::Entities::Query::Brand
      when 'Product'
        products = Product.order(:name).find(params[:sellable_ids])
        present :sellables, products, with: AdminAPIV1::Entities::Query::Product
      end
    end
  end

  desc 'Interface for retrieving regions and states'
  namespace :regions do
    get do
      present RegionData.new, with: AdminAPIV1::Entities::Query::RegionalDataEntity
    end
  end
end
