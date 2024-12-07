class AdminAPIV1::Entities::Query::PaymentProfileEntity < Grape::Entity
  expose :id, as: :value
  expose :label

  def label
    object.name
  end
end
