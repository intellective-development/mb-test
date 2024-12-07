class AdminAPIV1::Entities::Query::Brand < Grape::Entity
  expose :id, as: :value
  expose :label do |brand|
    name = "#{brand.name} (id: #{brand.id})"
    brand.parent&.name ? "#{brand.parent.name} > #{name}" : name
  end
end
