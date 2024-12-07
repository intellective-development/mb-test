module Shared::Helpers::GiftParamHelpers
  extend Grape::API::Helpers

  params :gift_detail_params do
    requires :recipient_name,   type: String, allow_blank: true
    requires :recipient_phone,  type: String, allow_blank: true
    optional :message,          type: String, allow_blank: true
    optional :recipient_email,  type: String, allow_blank: true
  end

  params :edit_gift_detail_params do
    optional :recipient_name,   type: String, allow_blank: true
    optional :recipient_phone,  type: String, allow_blank: true
    optional :message,          type: String, allow_blank: true
    optional :recipient_email,  type: String, allow_blank: true
    at_least_one_of :recipient_name, :recipient_phone, :message, :recipient_email
  end
end
