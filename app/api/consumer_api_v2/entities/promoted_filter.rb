class ConsumerAPIV2::Entities::PromotedFilter < Grape::Entity
  expose :description
  expose :name
  expose :term

  def name
    object['name']
  end

  def term
    object['term']
  end

  def description
    object['description']
  end
end
