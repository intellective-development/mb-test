module Shared::Helpers::StorefrontParamHelper
  extend Grape::API::Helpers

  params :storefront_params do
    requires :storefront, type: Hash do
      requires :business_id, type: Integer, allow_blank: false
      requires :supplier_fee_mode, type: String, values: Storefront.supplier_fee_modes.keys, allow_blank: false
      requires :single_shipping_fee, type: BigDecimal, allow_blank: false
      requires :support_email, type: String, allow_blank: false
      requires :pim_name, type: String, allow_blank: false
      requires :name, type: String, allow_blank: false

      optional :hostname, type: String, allow_blank: false
      optional :ecp_provider, type: String, values: Storefront.ecp_providers.keys, allow_blank: false
      optional :engraving_fee, type: BigDecimal, allow_blank: false
      optional :home_url, type: String, allow_blank: false
      optional :oauth_application_id, type: Integer, allow_blank: false
      optional :google_tag_id, type: String, allow_blank: false
      optional :segment_tag_id, type: String, allow_blank: false
      optional :n_rsa_count, type: Integer, allow_blank: false
      optional :rsa_price_type, type: Integer, allow_blank: false
      optional :apple_merchant_name, type: String, allow_blank: false
      optional :apple_merchant_id, type: String, allow_blank: false
      optional :tracking_page_hostname, type: String, allow_blank: false
      optional :legal_text, type: String, allow_blank: false
      optional :ga_id, type: String, allow_blank: false
      optional :status, type: String, values: Storefront.statuses.keys, allow_blank: false
      optional :support_phone_number, type: String, allow_blank: false
      optional :email_capture_mode, type: String, values: Storefront.email_capture_modes.keys, allow_blank: false
      optional :email_capture_title, type: String, allow_blank: false
      optional :email_capture_subtitle, type: String, allow_blank: false
      optional :shipped_method_desc, type: String, allow_blank: false
      optional :on_demand_method_desc, type: String, allow_blank: false
      optional :merchandise_fulfillment_desc, type: String, allow_blank: false
      optional :back_order_method_desc, type: String, allow_blank: false
      optional :threejms_brand, type: String, allow_blank: false
      optional :button_color, type: String, allow_blank: false
      optional :footer_copy, type: String, allow_blank: false
      optional :age_verify_copy, type: String, allow_blank: false
      optional :enable_authenticated_checkout, type: Boolean, allow_blank: false
      optional :enable_auto_refill, type: Boolean, allow_blank: false
      optional :enable_substitution, type: Boolean, allow_blank: false
      optional :enable_footer, type: Boolean, allow_blank: false
      optional :enable_in_stock_check, type: Boolean, allow_blank: false
      optional :enable_live_chat, type: Boolean, allow_blank: false
      optional :enable_side_referral, type: Boolean, allow_blank: false
      optional :enable_supplier_order_mins, type: Boolean, allow_blank: false
      optional :enable_sms_opt_in, type: Boolean, allow_blank: false
      optional :enable_email_opt_in, type: Boolean, allow_blank: false
      optional :default_sms_opt_in, type: Boolean, allow_blank: false
      optional :default_email_opt_in, type: Boolean, allow_blank: false
      optional :enable_back_order_placement, type: Boolean, allow_blank: false
      optional :enable_engravings, type: Boolean, allow_blank: false
      optional :enable_pre_sale_placement, type: Boolean, allow_blank: false
      optional :enable_sift_fraud, type: Boolean, allow_blank: false
      optional :enable_multiple_coupons, type: Boolean, allow_blank: false
      optional :enable_birthdate_collection, type: Boolean, allow_blank: false
      optional :enable_legal_age_collection, type: Boolean, allow_blank: false
      optional :enable_video_gift_message, type: Boolean, allow_blank: false
      optional :enable_dynamic_shipping, type: Boolean, allow_blank: false
      optional :enable_mikmak_feed, type: Boolean, allow_blank: false
      optional :enable_graphic_engraving, type: Boolean, allow_blank: false
      optional :inherits_tracking_page, type: Boolean, allow_blank: false
      optional :fulfillment_types, type: Array[String], allow_blank: false
      optional :is_liquid, type: Boolean, allow_blank: false
      optional :client_id, type: String, allow_blank: false
      optional :sdk_whitelisted_domains, type: Array[String]
    end

    optional :liquid_token, type: String, allow_blank: false
  end
end
