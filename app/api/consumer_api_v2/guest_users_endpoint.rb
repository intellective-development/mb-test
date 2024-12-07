class ConsumerAPIV2::GuestUsersEndpoint < BaseAPIV2
  helpers Shared::Helpers::AuthHelpers

  namespace :guest_user do
    before do
      validate_device_udid!
    end

    post do
      present :guest_user, create_guest_user, with: ConsumerAPIV2::Entities::User
    end
  end
end
