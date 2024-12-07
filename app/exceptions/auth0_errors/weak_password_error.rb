# frozen_string_literal: true

module Auth0Errors
  class WeakPasswordError < Auth0Error
    def message
      'The password is too weak.'
    end
  end
end
