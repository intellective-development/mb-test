class Admin::StorefrontsController < Admin::BaseController
  delegate :sort_column, :sort_direction, to: :list_storefronts
  helper_method :sort_column, :sort_direction

  before_action :load_storefront, only: %i[edit update toggle_status test_webhook]
  before_action :load_membership_plan, only: %i[edit update]
  before_action :set_recaptcha_domains, only: %i[edit]

  rescue_from ::Google::Cloud::Error do |e|
    flash[:error] = e.message
    redirect_to action: :index if %w[update].include? action_name
  end

  def index
    @storefronts = list_storefronts.result
  end

  def update
    if update_storefront(storefront_params).success?
      redirect_to action: :index
    else
      flash[:error] = 'The storefront could not be updated'
      render action: :edit
    end
  end

  def toggle_status
    new_status = @storefront.active? ? 'inactive' : 'active'
    notice = update_storefront(status: new_status).success? ? nil : 'The storefront could not be updated'

    redirect_to({ action: :index }, notice: notice)
  end

  def test_webhook
    begin
      response_json = Webhook::OrderUpdateWebhookWorker.new.perform(@storefront.orders.last.id)
    rescue StandardError => e
      response_json = { message: 'error', description: e.message }
    end

    respond_to do |format|
      format.json do
        render json: response_json
      end
    end
  end

  private

  def list_storefronts
    @list_storefronts ||= ::Storefronts::List.new(params).call
  end

  def update_storefront(update_params)
    ::Storefronts::Update.new(@storefront, update_params).call
  end

  def load_storefront
    @storefront = Storefront.find(params[:id])
  end

  def load_membership_plan
    @membership_plan =
      @storefront.membership_plan ||
      MembershipPlan.new(name: MembershipPlans::Base::NAME, billing_frequency: 12)
  end

  def storefront_params
    params.require(:storefront).permit(
      :business_id,
      :button_color,
      :ecp_provider,
      :email_capture_mode,
      :email_capture_subtitle,
      :email_capture_title,
      :enable_authenticated_checkout,
      :enable_auto_refill,
      :enable_footer,
      :enable_in_stock_check,
      :enable_live_chat,
      :enable_side_referral,
      :enable_substitution,
      :enable_supplier_order_mins,
      :favicon_file,
      :footer_copy,
      :google_tag_id,
      :home_url,
      :hostname,
      :logo_file,
      :mobile_logo_file,
      :auth0_logo_file,
      :name,
      :oauth_application_id,
      :segment_tag_id,
      :engraving_fee,
      :single_shipping_fee,
      :success_content_mobile_screen_id,
      :supplier_fee_mode,
      :support_email,
      :support_phone_number,
      :threejms_brand,
      :auth_provider,
      :auth0_domain,
      :auth0_client_id,
      :auth0_client_secret,
      :auth0_audience,
      :auth0_db_connection,
      :auth0_api_client_id,
      :auth0_api_client_secret,
      :auth0_api_domain,
      :segment_write_key,
      :iterable_api_key,
      :enable_sms_opt_in,
      :enable_engravings,
      :enable_email_opt_in,
      :shipped_method_desc,
      :on_demand_method_desc,
      :enable_back_order_placement,
      :enable_pre_sale_placement,
      :enable_sift_fraud,
      :enable_multiple_coupons,
      :merchandise_fulfillment_desc,
      :back_order_method_desc,
      :enable_birthdate_collection,
      :age_verify_copy,
      :enable_legal_age_collection,
      :enable_video_gift_message,
      :n_rsa_count,
      :rsa_price_type,
      :enable_dynamic_shipping,
      :apple_merchant_name,
      :apple_merchant_id,
      :tracking_page_hostname,
      :enable_mikmak_feed,
      :enable_graphic_engraving,
      :is_liquid,
      :inherits_tracking_page,
      :parent_storefront_id,
      :legal_text,
      :sms_legal_text,
      :ga_id,
      :custom_checkout_css,
      :enable_checkout_v3,
      :min_selection_price,
      :max_selection_price,
      :enable_price_range_selection,
      :allow_price_range_fallback,
      :enable_zone_proximity_selection,
      :omit_comms,
      :default_sms_opt_in,
      :default_email_opt_in,
      :sdk_whitelisted_domains,
      :enable_oos_availability_check,
      :oos_amount_willing_to_cover,
      :shipping_fee_covered_by_rb,
      webhook_attributes: %i[url enabled],
      recaptcha_domains: [names: []],
      fulfillment_types: [],
      membership_plans: %i[
        name state price engraving_percent_off free_on_demand_fulfillment_threshold
        free_shipping_fulfillment_threshold no_service_fee
        trial_period trial_duration trial_duration_unit
      ]
    ).tap do |storefront_params|
      storefront_params.merge!(sdk_whitelisted_domains: storefront_params[:sdk_whitelisted_domains]&.squish&.delete(' ')&.split(','))
    end
  end

  def recaptcha_allowed_domains
    return ::Google::CloudPlatform.new.allowed_domains if Feature[:enable_gcp].enabled?

    []
  end

  def set_recaptcha_domains
    @recaptcha_domains = recaptcha_allowed_domains
  end
end
