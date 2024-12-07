# frozen_string_literal: true

module Auth0Errors
  class AccountAlreadyExistsError < Auth0Error
    def message
      'You already have an account. Please login.'
    end
  end
end
