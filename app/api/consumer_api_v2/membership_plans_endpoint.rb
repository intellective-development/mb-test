class ConsumerAPIV2::MembershipPlansEndpoint < ConsumerAPIV2
  namespace :membership_plans do
    desc 'Retrives a list of membership plans', ConsumerAPIV2::DOC_AUTH_HEADER
    get do
      @membership_plans = MembershipPlan.active.where(storefront: storefront)

      present @membership_plans, with: ConsumerAPIV2::Entities::MembershipPlan
    end
  end
end
