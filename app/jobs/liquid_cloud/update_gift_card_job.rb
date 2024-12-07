# frozen_string_literal: true

# Liquid Cloud Module
module LiquidCloud
  # Update Gift Card Job
  class UpdateGiftCardJob < LiquidCloud::BaseJob
    LIQUID_CLOUD_GIFT_CARS_PATH = '/v1/giftcards'

    def perform(coupon_id)
      return true unless Feature[:update_liquid_services].enabled?

      coupon = Coupon.find(coupon_id)

      conn.put("#{LIQUID_CLOUD_GIFT_CARS_PATH}/#{coupon.code}") do |req|
        req.body = {
          code: coupon.code,
          active: coupon.active,
          pimName: coupon.storefront.pim_name,
          storefrontId: coupon.storefront.id,
          description: coupon.description
        }
      end
    end
  end
end
