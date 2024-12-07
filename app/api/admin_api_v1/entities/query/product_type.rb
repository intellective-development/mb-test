class AdminAPIV1::Entities::Query::ProductType < Grape::Entity
  expose :id, as: :value
  expose :label do |pt|
    names = pt.ancestors.sort_by(&:level).map(&:name) + [pt.name]
    names.join(' | ')
  end
end
