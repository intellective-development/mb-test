class ConsumerAPIV2::Entities::Type < Grape::Entity
  expose :id
  expose :name
  expose :position
  expose :permalink
  expose :count do |type, options|
    # this triples the length of the metadata generation. considering that we already know the prods are present,
    # we should consider nuking it. Short term, could hardcode any non zero integer.
    products = type.products.pluck(:id) & options[:product_ids]
    products.count
  end
end

def sub_types
  []
end
