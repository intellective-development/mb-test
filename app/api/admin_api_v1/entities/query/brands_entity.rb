class AdminAPIV1::Entities::Query::BrandsEntity < Grape::Entity
  present_collection true

  expose :items, as: :brands do |object, _|
    object[:items].each_with_object({}) { |brand, hash| hash[brand.permalink] = AdminAPIV1::Entities::Query::BrandEntity.new(brand) }
  end
end
