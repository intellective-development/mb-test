# frozen_string_literal: true

module DefaultHeaders
  extend ActiveSupport::Concern

  included do
    finally do
      header 'Strict-Transport-Security', Rails.configuration.x.strict_transport_security_header
      header 'Content-Security-Policy', Rails.configuration.x.content_security_policy_header
      header 'Permissions-Policy', Rails.configuration.x.permissions_policy_header
      header 'Referrer-Policy', Rails.configuration.x.referrer_policy_header
    end
  end
end
