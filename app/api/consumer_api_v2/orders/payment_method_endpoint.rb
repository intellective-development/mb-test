class ConsumerAPIV2::Orders::PaymentMethodEndpoint < BaseAPIV2
  helpers Shared::Helpers::BillingHelper, Shared::Helpers::BillingParamHelpers

  before do
    authenticate!
    error!('Invalid request', 400) if !valid_payment_partner_request? || !valid_hmac_signed_request?
  end

  namespace :user do
    namespace :payment_partner do
      namespace :payment_profile do
        desc 'Receives payment_method_nonce param encrypted with shared HMAC secret, decrypts the param and associates it with the given order.', Shared::Helpers::PaymentPartners::Authenticatable::PAYMENT_PARTNER_AUTH_HEADERS
        params do
          use :billing_address
          use :billing_details
          optional :supplier_id, type: String, allow_blank: false, desc: 'ID of supplier whose merchant account will be used for verification. In the event of multiple supplers (comma separated) then the first will be used.'
        end

        post do
          payment_profile = validate_and_create_payment_profile(params)
          error!(no_payment_profile_error_msg, 400) unless payment_profile

          present payment_profile, with: ConsumerAPIV2::Entities::PaymentProfile
        end
      end
    end
  end
end
