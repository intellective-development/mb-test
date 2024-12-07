# frozen_string_literal: true

module Auth0Errors
  class TokenDecodeError < Auth0Error
    def initialize(msg = '')
      @msg = "There was an error while decoding your access token. #{msg}"

      super(@msg)
    end
  end
end
