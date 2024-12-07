class ConsumerAPIV2::Entities::Survey < Grape::Entity
  expose :token
  expose :comment
  expose :score
  expose :state
  expose :referral_code do |model|
    model.user.referral_code
  end
end
