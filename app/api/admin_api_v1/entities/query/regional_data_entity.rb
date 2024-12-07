class AdminAPIV1::Entities::Query::RegionalDataEntity < Grape::Entity
  expose :states do |object, _|
    object[:states].each_with_object({}) { |state, hash| hash[state.slug] = AdminAPIV1::Entities::Query::StateEntity.new(state) }
  end

  expose :regions do |object, _|
    object[:regions].each_with_object({}) { |region, hash| hash[region.slug] = AdminAPIV1::Entities::Query::RegionEntity.new(region) }
  end
end
