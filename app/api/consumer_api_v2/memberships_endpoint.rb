class ConsumerAPIV2::MembershipsEndpoint < ConsumerAPIV2
  helpers Shared::Helpers::AuthHelpers
  namespace :memberships do
    before do
      authenticate!
      validate_device_udid!
    end

    desc 'Retrives a list of customer memberships', ConsumerAPIV2::DOC_AUTH_HEADER
    get do
      @memberships = Membership.where(user: @user, storefront: storefront)

      present @memberships, with: ConsumerAPIV2::Entities::Membership
    end
  end
end
