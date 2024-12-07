# frozen_string_literal: true

##
# LiquidCommerceIdConverter
#
# Converts MongoDB ObjectIDs to PostgresSQL-compatible bigint identifiers.
# Optimized for handling 24-character MongoDB ObjectIDs while ensuring:
# - Deterministic conversion (same input always produces same output)
# - Collision resistance through timestamp preservation
# - PostgresSQL bigint compatibility (values between 1 and 2^63 - 1)
#
# @example Basic usage
#   id = "6748e43b59756813d3c0bf22"  # MongoDB ObjectID
#   numeric_id = LiquidCommerceIdConverter.to_numeric(id)
#   # => Returns PostgresSQL-compatible bigint
#
module LiquidCommerceIdConverter
  POSTGRES_BIGINT_MAX = (2**63) - 1

  class << self
    def to_numeric(object_id)
      return nil unless valid_object_id?(object_id)

      # Take first 16 chars of ObjectId for consistent numeric generation
      numeric = object_id[0...16].to_i(16)

      # Ensure positive value
      ((numeric % POSTGRES_BIGINT_MAX) + 1)
    end

    private

    def valid_object_id?(value)
      value.is_a?(String) && value.length == 24 && value.match?(/\A[0-9a-f]{24}\z/i)
    end
  end
end