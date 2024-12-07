require 'sift'

module Fraud
  class Score
    class << self
      include Fraud::SiftRetryableCaller

      ABUSE_TYPES = %w[
        payment_abuse
        promotion_abuse
        account_takeover
        account_abuse
      ].freeze

      def sift_score_and_reasons(user)
        call_and_retry { client.get_user_score(user.referral_code, abuse_types: ABUSE_TYPES) }
      end

      def promo_abuse_latest_decision(response)
        response&.body&.dig('latest_decisions', 'promotion_abuse', 'id')
      end

      def promo_abuse_reasons(response)
        reasons = {}

        response&.body&.dig('scores', 'promotion_abuse', 'reasons')&.each do |reason|
          reasons[reason['name']] = reason['value'] || true
        end

        reasons
      end

      def list_fraudulent_accounts(response)
        abuses = {}

        ABUSE_TYPES.each do |abuse_type|
          abuse_values = response&.body&.dig('scores', abuse_type)
          next unless abuse_values && abuse_values['score']

          abuses[abuse_type] = {
            score: abuse_values['score'],
            reasons: related_accounts(abuse_values['reasons'])
          }
        end

        abuses
      end

      private

      def client
        Sift::Client.new(
          api_key: ENV['SIFT_SCIENCE_API_KEY'],
          account_id: ENV['SIFT_ACCOUNT_ID'],
          version: ENV['SIFT_API_VERSION'] || 205
        )
      end

      def related_accounts(reasons)
        reasons&.map do |reason|
          {
            name: reason['name'],
            accounts: reason.dig('details', 'users')&.split(',')
          }
        end
      end
    end
  end
end
