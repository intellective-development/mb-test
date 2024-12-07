# frozen_string_literal: true

module Auth0Errors
  class InvalidCertificateError < Auth0Error
    def message
      'JWK certificate is invalid.'
    end
  end
end
