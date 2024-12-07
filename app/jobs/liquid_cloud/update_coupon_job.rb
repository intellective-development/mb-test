# frozen_string_literal: true

# Liquid Cloud Module
module LiquidCloud
  # Update Coupon Job
  class UpdateCouponJob < LiquidCloud::BaseJob
    LIQUID_CLOUD_COUPONS_PATH = '/v1/coupons'

    def perform(coupon_id)
      return true unless Feature[:update_liquid_services].enabled?

      coupon = Coupon.find(coupon_id)
      type = coupon.type.split('Coupon').last
      rule_type = coupon.sellable_restriction_excludes ? 'EXCLUDE' : 'RESTRICT_TO'

      product_ids = []
      product_type_ids = []
      brand_ids = []
      supplier_ids = []

      coupon.coupon_items.each do |item|
        binding.local_variable_get("#{item.item_type.underscore}_ids").push(item.item_id)
      end

      conn.put("#{LIQUID_CLOUD_COUPONS_PATH}/#{coupon.code}") do |req|
        req.body = {
          code: coupon.code,
          description: coupon.description,
          pimName: coupon.storefront.pim_name,
          storefrontId: coupon.storefront.id,
          reportingTypeId: coupon.reporting_type_id,
          type: type,
          discounts: {
            amount: coupon.amount.to_f,
            percent: coupon.percent,
            engravingPercent: coupon.engraving_percent,
            maximumDiscountValue: coupon.maximum_value.to_f,
            freeDelivery: coupon.free_delivery,
            freeServiceFee: coupon.free_service_fee,
            freeShipping: coupon.free_shipping,
            freeProduct: {
              id: coupon.free_product_id,
              nthCount: coupon.free_product_id_nth_count
            }
          },
          restrictions: {
            minimumOrderValue: coupon.minimum_value.to_f,
            minimumOrderUnits: coupon.minimum_units,
            nthUserOrder: coupon.nth_order,
            nthOrderItem: coupon.nth_order_item,
            applyToAllItems: coupon.sellable_type == 'All',
            startsAt: coupon.starts_at,
            expiresAt: coupon.expires_at,
            restrictMaxDiscount: coupon.restrict_items,
            singleUse: coupon.single_use,
            quota: coupon.quota,
            excludePreSaleItems: coupon.exclude_pre_sale,
            domainName: coupon.domain_name,
            membershipPlanId: coupon.membership_plan_id,
            redeemablePartnerIds: coupon.doorkeeper_application_ids,
            retailerType: coupon.supplier_type,
            sellableRestrictions: {
              productIds: product_ids.presence,
              productTypeIds: product_type_ids.presence,
              brandIds: brand_ids.presence,
              retailerIds: supplier_ids.presence,
              ruleType: rule_type
            }
          }
        }
      end
    end
  end
end
