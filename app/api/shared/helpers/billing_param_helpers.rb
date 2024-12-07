module Shared
  module Helpers
    module BillingParamHelpers
      extend Grape::API::Helpers

      params :billing_address do
        requires :address,    type: Hash do
          requires :name,     type: String, allow_blank: false
          requires :address1, type: String, allow_blank: false
          optional :address2, type: String, allow_blank: true, default: ''
          optional :state,    type: String, allow_blank: true
          requires :zip_code, type: String, regexp: /^(\d){5}/
          optional :city,     type: String, allow_blank: true
        end
      end

      params :cc_details do
        optional :cc_number,   type: String, allow_blank: false
        optional :cc_exp_date, type: String, allow_blank: false
        optional :cc_cvv,      type: String, allow_blank: false
      end

      params :billing_details do
        optional :payment_method_nonce, type: String, allow_blank: false, desc: 'payment_method_nonce param from Braintree encrypted with shared HMAC secret.'
        optional :device_data,          type: String, desc: 'Device fingerprint data used for anti-fraud risk scoring'
        optional :default,              type: Boolean, desc: 'Set this payment profile as the default'
        optional :apple_pay,            type: Boolean, desc: 'Set this payment profile as Apple Pay'
        optional :paypal,               type: Boolean, desc: 'Set this payment profile as PayPal'
        optional :payment_type,         type: String, allow_blank: true, values: PaymentProfile::PAYMENT_TYPES

        mutually_exclusive :apple_pay, :payment_type
        mutually_exclusive :paypal, :payment_type
      end
    end
  end
end
