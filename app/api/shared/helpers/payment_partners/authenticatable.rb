# frozen_string_literal: true

module Shared::Helpers::PaymentPartners
  module Authenticatable
    extend Grape::API::Helpers

    class ValidationError < StandardError; end

    PAYMENT_PARTNER_AUTH_HEADERS = {
      headers: {
        'X-Payment-Partner-Id' => { description: 'Payment Partner\'s client_id', required: true },
        'X-Payment-Partner-Key' => { description: 'Payment Partner\'s client_secret', required: true },
        'X-Payment-Request-Hash' => { description: 'Payment Partner\'s salted timestamp hash', required: true },
        'X-Payment-Partner-Request-Timestamp' => { description: 'Payment Partner\'s request timestamp', required: true },
        'X-Payment-Partner-Hmac-Signature' => { description: 'Payment Partner\'s request HMAC signature', required: false }
      }
    }.freeze

    TIMESTAMP_THRESHOLD_IN_SECONDS = 3

    def valid_payment_partner_request?
      return false if time_diff >= TIMESTAMP_THRESHOLD_IN_SECONDS

      return false if payment_partner.nil?

      payment_partner_hash_header == digested_payment_partner_md5
    end

    def valid_hmac_signed_request?
      payment_partner_hmac_sign_header == base64_encoded_hmac
    end

    def logged_payment_partner
      payment_partner if valid_payment_partner_request?
    end

    def logged_payment_partner!
      raise ValidationError unless valid_payment_partner_request?

      payment_partner
    end

    private

    def base64_encoded_hmac
      Base64.encode64(OpenSSL::HMAC.digest('SHA256', payment_partner&.hmac_secret || '', request.body.read)).strip.encode('utf-8')
    end

    def time_diff
      @time_diff ||= Time.current.to_i - payment_partner_timestamp_header
    end

    def digested_payment_partner_md5
      Digest::MD5.hexdigest([payment_partner&.api_salt_secret, payment_partner_timestamp_header].join(','))
    end

    def payment_partner
      return @payment_partner if defined?(@payment_partner)

      @payment_partner = PaymentPartner.find_by(api_client_id: payment_partner_id_header, api_client_secret: payment_partner_key_header)
    end

    def payment_partner_hash_header
      headers['X-Payment-Request-Hash']
    end

    def payment_partner_id_header
      headers['X-Payment-Partner-Id']
    end

    def payment_partner_key_header
      headers['X-Payment-Partner-Key']
    end

    def payment_partner_timestamp_header
      headers['X-Payment-Partner-Request-Timestamp'].presence || 0
    end

    def payment_partner_hmac_sign_header
      headers['X-Payment-Partner-Hmac-Signature']
    end
  end
end
