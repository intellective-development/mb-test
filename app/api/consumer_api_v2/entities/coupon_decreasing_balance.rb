class ConsumerAPIV2::Entities::CouponDecreasingBalance < Grape::Entity
  expose :id
  expose :code
  expose :amount
  expose :type
  expose :balance
  expose :expires_at
end
