class AdminAPIV1::Entities::Query::ProductGrouping < Grape::Entity
  expose :id, as: :value
  expose :label do |psg|
    "#{psg.name} (id: #{psg.id})"
  end
end
