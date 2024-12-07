class JwtTokenService
  HMAC_SECRET = ENV['JWT_HMAC_SECRET']

  class << self
    def encode(payload)
      JWT.encode payload, HMAC_SECRET, 'HS256'
    end

    def decode(token)
      result = JWT.decode token, HMAC_SECRET, true, { algorithm: 'HS256' }
      result[0]
    end
  end
end
