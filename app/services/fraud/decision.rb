require 'sift'

module Fraud
  class Decision
    include SiftRetryableCaller

    DECISION_TYPES = {
      account_recovered: 'account_recovered_account_takeover',
      session_fraud_cleared: 'session_looks_ok_account_takeover',
      session_fraud: 'session_looks_bad_account_takeover',
      fraud_cleared: 'looks_ok_payment_abuse',
      fraud: 'looks_bad_payment_abuse',
      order_fraud_cleared: 'order_looks_bad_payment_abuse',
      order_fraud: 'order_looks_ok_payment_abuse',
      order_promo_fraud_cleared: 'order_looks_ok_promotion_abuse',
      order_promo_fraud: 'order_looks_bad_promotion_abuse',
      promo_fraud_cleared: 'looks_ok_promotion_abuse',
      promo_fraud: 'looks_bad_promotion_abuse',
      payment_abuse_unkown: 'not_enough_data_payment_abuse',
      storefront_bypass: 'storefront_fraud_bypass_payment_abuse'
    }.freeze

    SOURCE_TYPES = {
      chargeback: 'chargeback',
      manual_review: 'manual_review',
      automated_rule: 'automated_rule'
    }.freeze

    def initialize(options)
      @options = options.symbolize_keys
    end

    def call
      call_and_retry { client.apply_decision(decision_properties) }
    end

    def call_async
      SiftDecisionWorker.perform_async(@options)
    end

    def self.from_authenticated_session(authenticated_session, session_decision)
      Decision.new(
        type: session_decision,
        source: 'manual_review',
        analyst: authenticated_session.notified_value,
        user_id: authenticated_session.user.referral_code,
        session_id: authenticated_session.session_id,
        time: Time.zone.now
      )
    end

    private

    def client
      @client ||= Sift::Client.new(
        api_key: ENV['SIFT_SCIENCE_API_KEY'],
        account_id: ENV['SIFT_ACCOUNT_ID'],
        version: ENV['SIFT_API_VERSION'] || 205
      )
    end

    def decision_properties
      {
        analyst: @options[:analyst],
        decision_id: DECISION_TYPES[@options[:type].to_sym],
        source: SOURCE_TYPES[@options[:source].to_sym],
        time: format_time(@options[:time]),
        user_id: @options[:user_id],
        session_id: @options[:session_id]
      }.compact
    end

    def format_time(time)
      return nil unless time

      Integer(time) * 1000
    end
  end
end
