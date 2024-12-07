class ConsumerAPIV2::Entities::CartTrait < Grape::Entity
  expose :coupon_code
  expose :gtm_visitor_id
  expose :gift_order
  expose :age_verified
  expose :decision_log_uuids
  expose :membership_plan_id
end
