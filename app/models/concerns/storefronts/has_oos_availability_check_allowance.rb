# frozen_string_literal: true

module Storefronts
  # Storefronts::HasOosAvailabilityCheckAllowance
  module HasOosAvailabilityCheckAllowance
    extend ActiveSupport::Concern

    included do
      validate :cannot_set_oos_amount_willing_to_cover_if_storefront_not_eligible
      before_save :set_oos_amount_willing_to_cover_to_nil_if_oos_availability_check_is_disabled
    end

    private

    def cannot_set_oos_amount_willing_to_cover_if_storefront_not_eligible
      errors.add(:oos_amount_willing_to_cover, 'cannot be set if OOS availability check is disabled') if oos_amount_willing_to_cover_changed? && !enable_oos_availability_check
    end

    def set_oos_amount_willing_to_cover_to_nil_if_oos_availability_check_is_disabled
      return unless enable_oos_availability_check_changed?(to: false)

      self.oos_amount_willing_to_cover = nil
    end
  end
end
