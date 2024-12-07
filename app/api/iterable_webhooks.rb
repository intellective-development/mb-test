class IterableWebhooks < BaseAPI
  helpers do
    def authenticate!
      request_token = headers['Authorization']
      valid_token = ENV['ITERABLE_WEBHOOK_AUTH_TOKEN']

      error!('Missing or invalid API Token', 401) unless request_token == valid_token
    end

    def coupon_percent?
      params[:type] == 'CouponPercent'
    end
  end

  params do
    requires :storefront_pim_name, type: String, allow_blank: false
    requires :type, type: String, allow_blank: false, values: %w[CouponValue CouponPercent CouponDecreasingBalance]
    optional :category, type: Float, allow_blank: false
    requires :description, type: String, allow_blank: false
    optional :value, type: String, allow_blank: false
    optional :free_del, type: Boolean
    optional :combine, type: Boolean
    requires :start_date, type: Date, allow_blank: false
    requires :exp_date, type: Date, allow_blank: false
    requires :min_unit, type: Integer, allow_blank: false
    optional :min_value, type: Integer, allow_blank: false
    optional :percent_value, type: Integer, allow_blank: false
    requires :usage_limit, type: Integer, allow_blank: false
    optional :supplier, type: String, allow_blank: false
    optional :skip_fraud_check, type: Boolean
    optional :exclude_pre_sale, type: Boolean, default: true
  end

  before do
    authenticate!
  end

  after_validation do
    error!('percent_value only allowed for CouponPercent', 400) if !coupon_percent? && params[:percent_value].present?
    error!('value only allowed for CouponPercent and CouponDecreasingBalance', 400) if coupon_percent? && params[:value].present?
  end

  get do
    storefront = Storefront.find_by(pim_name: params[:storefront_pim_name])
    @coupon = Coupon.create!(
      minimum_value: params[:min_value],
      minimum_units: params[:min_unit],
      combine: params[:combine] || true,
      type: params[:type],
      code: Coupon.generate_gift_card_code,
      description: params[:description],
      expires_at: params[:exp_date],
      starts_at: params[:start_date],
      reporting_type_id: params[:category],
      amount: params[:value],
      free_delivery: params[:free_del] || false,
      quota: params[:usage_limit],
      skip_fraud_check: params[:skip_fraud_check] || false,
      storefront_id: storefront.id,
      exclude_pre_sale: params[:exclude_pre_sale],
      percent: params[:percent_value]
    )
    { title: @coupon.code, code: @coupon.code }.to_json
  end
end
