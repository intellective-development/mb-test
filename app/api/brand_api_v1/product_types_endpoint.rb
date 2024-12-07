class BrandAPIV1::ProductTypesEndpoint < BaseAPIV1
  namespace :product_types do
    desc 'Returns currently active product types'
    get do
      product_types = ProductType.includes(children: [:children])
                                 .order(:position)
                                 .root
                                 .active
                                 .joins(:image)
                                 .where("images.imageable_type = 'ProductType'")
                                 .where('images.imageable_id = product_types.id')

      present product_types, with: BrandAPIV1::Entities::ProductType
    end
  end
end
