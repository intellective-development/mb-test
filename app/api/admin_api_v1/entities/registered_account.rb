# frozen_string_literal: true

class AdminAPIV1
  module Entities
    # AdminAPIV1::Entities::RegisteredAccount
    class RegisteredAccount < Grape::Entity
      expose :id
      expose :email
      expose :first_name
      expose :last_name
      expose :provider
      expose :uid
      expose :storefront_account_id
      expose :storefront_id
    end
  end
end
