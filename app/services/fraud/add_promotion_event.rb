module Fraud
  class AddPromotionEvent < Event
    def initialize(user, session, request, order, coupon, errors)
      session.id = nil if session # $session_id not supported yet
      super(user, session, request)
      @order = order
      @coupon = coupon
      @errors = errors
    end

    def self.event_type
      '$add_promotion'
    end

    def properties
      props = super
      params = promo_abuse_params
      props['$promotions'] = [
        if @coupon
          valid_coupon_properties(params)
        else
          invalid_coupon_properties(params)
        end
      ]
      props
    end

    def call_and_run_workflow
      response = notify_sift(
        self.class.event_type,
        properties,
        return_workflow_status: true,
        abuse_types: ['promotion_abuse']
      )
      {
        score: response&.body&.dig('score_response', 'scores', 'promotion_abuse', 'score'),
        decision: response&.body&.dig('score_response', 'workflow_statuses')&.first&.dig('history')&.find { |app| app['app'] == 'decision' }&.dig('config', 'decision_id')
      }
    end

    private

    SIFT_SUCCESS                = '$success'.freeze
    SIFT_FAILURE                = '$failure'.freeze
    SIFT_FAILURE_EXPIRED        = '$expired'.freeze
    SIFT_FAILURE_ALREADY_USED   = '$already_used'.freeze
    SIFT_FAILURE_NOT_APPLICABLE = '$not_applicable'.freeze
    SIFT_FAILURE_INVALID_CODE   = '$invalid_code'.freeze

    def valid_coupon_properties(params)
      {
        '$promotion_id' => params[:coupon].code,
        '$status' => params[:status],
        '$failure_reason' => params[:failure_reason],
        '$description' => params[:coupon]&.description,
        '$referrer_user_id' => params[:referrer_user_id],
        '$discount' => {
          '$percentage_off' => params[:coupon].percent&.zero? ? nil : Float(params[:coupon].percent || 0) / 100,
          '$amount' => currency_amount(Integer(params[:coupon].amount || 0)),
          '$currency_code' => 'USD',
          '$minimum_purchase_amount' => currency_amount(params[:coupon].minimum_value)
        }
      }
    end

    def invalid_coupon_properties(params)
      {
        '$promotion_id' => params[:coupon_code],
        '$status' => params[:status],
        '$failure_reason' => params[:failure_reason],
        '$referrer_user_id' => params[:referrer_user_id]
      }
    end

    def promo_abuse_params
      {
        status: @errors&.none? ? SIFT_SUCCESS : SIFT_FAILURE,
        failure_reason: failure_reason,
        coupon: @coupon,
        referrer_user_id: @coupon.is_a?(CouponReferral) ? @coupon&.code : nil
      }
    end

    def failure_reason
      return SIFT_FAILURE_INVALID_CODE unless @errors

      if @errors.include?(I18n.t(:eligible, { scope: 'coupons.errors' }))
        SIFT_FAILURE_EXPIRED
      elsif @errors.include?(I18n.t(:customer, { scope: 'coupons.errors' }))
        SIFT_FAILURE_ALREADY_USED
      else
        SIFT_FAILURE_NOT_APPLICABLE
      end
    end
  end
end
