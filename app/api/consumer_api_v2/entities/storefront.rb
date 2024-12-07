# frozen_string_literal: true

class ConsumerAPIV2::Entities::Storefront < Grape::Entity
  expose :id
  expose :name
  expose :business, with: ConsumerAPIV2::Entities::Business
  expose :button_color
  expose :pim_name
  expose :ecp_provider
  expose :footer_copy
  expose :status
  expose :google_tag_id
  expose :segment_tag_id
  expose :home_url
  expose :priority_hostname, as: 'hostname'
  expose :email_capture_mode
  expose :email_capture_title
  expose :email_capture_subtitle
  expose :enable_authenticated_checkout
  expose :enable_auto_refill
  expose :enable_footer
  expose :enable_in_stock_check
  expose :enable_live_chat
  expose :enable_side_referral
  expose :enable_substitution
  expose :enable_supplier_order_mins
  expose :favicon_url
  expose :logo_url
  expose :mobile_logo_url
  expose :auth0_logo_url
  expose :fulfillment_types
  expose :success_page_name
  expose :single_shipping_fee
  expose :engraving_fee
  expose :supplier_fee_mode
  expose :storefront_links
  expose :storefront_fonts, with: ConsumerAPIV2::Entities::StorefrontFont
  expose :auth_provider
  expose :auth0_domain
  expose :auth0_client_id
  expose :auth0_audience
  expose :auth0_db_connection
  expose :support_email
  expose :support_phone_number
  expose :enable_sms_opt_in
  expose :enable_email_opt_in
  expose :default_sms_opt_in
  expose :default_email_opt_in
  expose :shipped_method_desc
  expose :on_demand_method_desc
  expose :enable_engravings
  expose :merchandise_fulfillment_desc
  expose :back_order_method_desc
  expose :age_verify_copy
  expose :enable_legal_age_collection
  expose :enable_video_gift_message
  expose :oauth_client_id do |storefront|
    storefront.oauth_application&.uid
  end
  expose :oauth_client_secret do |storefront|
    storefront.oauth_application&.secret
  end
  expose :video_gift_fee do |storefront|
    storefront.business.video_gift_fee
  end
  expose :enable_birthdate_collection
  expose :apple_merchant_id
  expose :apple_merchant_name
  expose :tracking_page_hostname
  expose :legal_text
  expose :sms_legal_text
  expose :ga_id
  expose :custom_checkout_css
  expose :enable_checkout_v3
end
