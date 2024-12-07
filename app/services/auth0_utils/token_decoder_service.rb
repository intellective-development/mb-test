# frozen_string_literal: true

module Auth0Utils
  class TokenDecoderService < BaseService
    API_PATH = '.well-known/jwks.json'

    attr_reader :client, :token, :storefront

    def initialize(token, storefront)
      @client = Auth0Client.new(storefront).call
      @token = token
      @storefront = storefront
    end

    def call
      retries ||= 0
      jwks_hash = fetch_or_store_jwks_hash
      decode_token(jwks_hash)
    rescue StandardError => e
      Rails.logger.error("Error decoding token. #{e.message}. token: #{token}")

      if (retries += 1) < 3
        sleep 0.5
        retry
      end

      notify_sentry_and_log(e, "TokenDecoderService Error: #{e.message}")
      raise e
    end

    private

    def fetch_or_store_jwks_hash
      cached_value = Rails.cache.fetch("#{storefront.id}_JWK_HASH")
      return formatted_certs(cached_value) if cached_value

      hash_to_cache = process_jwks_keys
      formatted_certs(hash_to_cache) if hash_to_cache && Rails.cache.write('JWK_HASH', hash_to_cache, expires_in: 1.hour)
    end

    def process_jwks_keys
      jwks_keys.each_with_object({}) do |jwks_key, hash|
        key = jwks_key['kid']
        decoded_x5c = Base64.decode64(jwks_key['x5c'].first)
        hash[key] = certificate_public_key(decoded_x5c)
      end
    rescue OpenSSL::X509::CertificateError => e
      Rails.logger.error("[InvalidCertificateError] Error formatting certs: #{e.message}")
      raise Auth0Errors::InvalidCertificateError
    end

    def certificate_public_key(decoded_x5c)
      OpenSSL::X509::Certificate.new(decoded_x5c).public_key.to_s
    end

    def formatted_certs(certs)
      certs.transform_values do |cert|
        OpenSSL::PKey::RSA.new(cert)
      end
    rescue OpenSSL::PKey::RSAError => e
      Rails.logger.error("[InvalidCertificateError] Error formatting certs: #{e.message}")
      raise Auth0Errors::InvalidCertificateError
    end

    def jwks_keys
      Array(body['keys'])
    end

    def body
      JSON.parse(request.body)
    end

    def request
      client.public_send(:get, API_PATH)
    end

    def decode_token(jwks_hash)
      JWT.decode(token, nil, true, jwt_decode_options) do |header|
        jwks_hash[header['kid']]
      end
    rescue JWT::VerificationError, JWT::DecodeError => e
      raise Auth0Errors::TokenDecodeError, e.message.to_s
    end

    def jwt_decode_options
      {
        algorithms: 'RS256', iss: client.url_prefix.to_s,
        verify_iss: true, verify_aud: true
      }
    end
  end
end
