# frozen_string_literal: true

module Google
  class CloudPlatform
    include SentryNotifiable

    attr_reader :client

    CACHE_KEY = 'recaptcha_allowed_domains'

    def initialize
      @client = ::Google::Cloud::RecaptchaEnterprise.recaptcha_enterprise_service
    rescue RuntimeError => e
      notify_sentry_and_log(e)
      raise ::Google::Cloud::CredentialsFileError
    end

    def recaptcha_key
      @recaptcha_key ||= client.get_key(name: "projects/#{ENV['GOOGLE_CLOUD_PROJECT']}/keys/#{ENV['GOOGLE_CLOUD_KEY']}")
    rescue ::Google::Cloud::Error => e
      notify_sentry_and_log(e)
      raise e
    end

    def allowed_domains(forced: false)
      Rails.cache.fetch(CACHE_KEY, force: forced, expires_in: 24.hours) do
        recaptcha_key.web_settings.allowed_domains.to_a
      end
    end

    def update_key_domains(domains)
      return false if allowed_domains.sort == domains.sort

      recaptcha_key.web_settings.allowed_domains = Google::Protobuf::RepeatedField.new(:string) + domains
      client.update_key(key: recaptcha_key)
      Rails.cache.delete(CACHE_KEY)
    rescue ::Google::Cloud::Error => e
      notify_sentry_and_log(e)
      raise e
    end
  end
end
