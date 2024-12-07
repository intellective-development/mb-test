# frozen_string_literal: true

class User
  # We need a user to be associated with actions like creating comments, cancelling shipments/orders, etc.
  # That's why we created this association to link Users and APIKeys and make it possible to get a user for a corresponding api key.
  module HasApiKeys
    extend ActiveSupport::Concern

    included do
      has_many :api_keys, dependent: :destroy
    end
  end
end
