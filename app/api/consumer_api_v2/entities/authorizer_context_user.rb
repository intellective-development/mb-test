class ConsumerAPIV2::Entities::AuthorizerContextUser < Grape::Entity
  expose :id
  expose :name
  expose :email
end
