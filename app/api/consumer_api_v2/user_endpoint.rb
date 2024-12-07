# frozen_string_literal: true

# User order numbers endpoint
class ConsumerAPIV2::UserEndpoint < BaseAPIV2
  namespace :user do
    params do
      requires :email, type: String, regexp: CustomValidators::Emails.email_validator
    end
    get :order_numbers do
      user = RegisteredAccount.find_by(email: params[:email], storefront: storefront)&.user

      error!('User not found.', 404) if user.blank?

      present user, with: ConsumerAPIV2::Entities::UserOrderNumbers
    end
  end
end
