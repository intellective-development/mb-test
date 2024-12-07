# frozen_string_literal: true

class EligibilityError < StandardError; end

module GiftCard
  # Class to check if a gift card is eligible for an order or a cart
  class GiftCardEligibilityService
    attr_accessor :gift_card
    attr_reader :previous_codes, :is_digital

    def initialize(order: nil, cart: nil)
      raise StandardError, 'You need to pass an order or a cart to this service' unless order.present? ^ cart.present?

      values_from_order(order) if order.present?
      values_from_cart(cart) if cart.present?
    end

    def eligible?(gift_card)
      @gift_card = gift_card

      check_already_included
      check_balance
      check_digital_only

      [true, nil]
    rescue EligibilityError => e
      [false, e.message]
    end

    private

    def values_from_order(order)
      @previous_codes = order.coupons.gift_card.pluck(:code)
      @is_digital = order.digital?
    end

    def values_from_cart(cart)
      @previous_codes = cart.gift_cards&.map(&:code) || []
      @is_digital = false
    end

    def check_already_included
      raise EligibilityError, error_str(:already_in_use) if previous_codes.include?(gift_card.code)
    end

    def check_balance
      raise EligibilityError, error_str(:generic) if gift_card.balance.zero?
    end

    def check_digital_only
      raise EligibilityError, error_str(:digital) if is_digital
    end

    def error_str(key, params = {})
      I18n.t(key, { scope: 'coupons.errors', promo_code: gift_card.code }.merge(params))
    end
  end
end
