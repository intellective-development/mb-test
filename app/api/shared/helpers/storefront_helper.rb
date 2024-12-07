module Shared::Helpers::StorefrontHelper
  def permitted_storefront_params(params)
    ActionController::Parameters
      .new(params[:storefront])
      .permit(
        :business_id, :supplier_fee_mode, :single_shipping_fee, :engraving_fee, :support_email, :name, :hostname,
        :ecp_provider, :home_url, :oauth_application_id, :google_tag_id, :segment_tag_id, :n_rsa_count,
        :rsa_price_type, :apple_merchant_name, :apple_merchant_id, :tracking_page_hostname, :legal_text,
        :ga_id, :status, :support_phone_number, :email_capture_mode, :email_capture_title,
        :email_capture_subtitle, :shipped_method_desc, :on_demand_method_desc, :merchandise_fulfillment_desc,
        :back_order_method_desc, :threejms_brand, :button_color, :footer_copy, :age_verify_copy,
        :enable_authenticated_checkout, :enable_auto_refill, :enable_substitution, :enable_footer,
        :enable_in_stock_check, :enable_live_chat, :enable_side_referral, :enable_supplier_order_mins,
        :enable_sms_opt_in, :enable_email_opt_in, :enable_back_order_placement, :enable_engravings,
        :enable_pre_sale_placement, :enable_sift_fraud, :enable_multiple_coupons, :enable_birthdate_collection,
        :enable_legal_age_collection, :enable_video_gift_message, :enable_dynamic_shipping, :enable_mikmak_feed,
        :enable_graphic_engraving, :inherits_tracking_page, :default_sms_opt_in, :default_email_opt_in, :is_liquid,
        :pim_name, :client_id, sdk_whitelisted_domains: [], fulfillment_types: []
      )
      .to_h
      .reverse_merge({ client_id: params[:liquid_token] }.compact)
      .presence
  end

  def sanitize_permalink(permalink)
    permalink.downcase.squish
  end
end
