class ConsumerAPIV2::RegionsEndpoint < BaseAPIV2
  helpers do
    def suppliers_by_region(slug, limit: 0)
      suppliers = Supplier.active.joins('join regions on regions.id = suppliers.region_id').where(supplier_type_id: [1, 2]).where('regions.slug = ?', slug)
      suppliers = suppliers.limit(limit) unless limit.zero?
      suppliers.order(:name)
    end
  end

  namespace :regions do
    params do
      optional :supplier_limit, type: Integer, default: 4
    end
    get do
      @regions_by_state = ShippingMethod.regions.collect do |s, r, l, t, r_id|
        suppliers = suppliers_by_region(l, limit: params[:supplier_limit]).map { |supplier| ConsumerAPIV2::Entities::RegionSupplier.new(supplier) }
        region = Region.find r_id
        { state: s, region: r, link: l, type: t, suppliers: suppliers, cities: region&.cities&.visible&.pluck(:name) }
      end
      @regions_by_state = @regions_by_state.group_by { |d| d[:state] }

      present @regions_by_state
    end

    route_param :slug do
      get do
        @suppliers = suppliers_by_region(params[:slug])
        @region = @suppliers.first&.region
        present :image, @region&.header_image&.file&.url
        present :region, @region, with: ConsumerAPIV2::Entities::Region
        present :suppliers, @suppliers, with: ConsumerAPIV2::Entities::RegionSupplier
      end
    end
  end
end
