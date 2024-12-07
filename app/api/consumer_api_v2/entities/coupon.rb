# frozen_string_literal: true

class ConsumerAPIV2::Entities::Coupon < Grape::Entity
  expose :active
  expose :storefront_id
  expose :code
  expose :amount
  expose :type
  expose :minimum_value
  expose :maximum_value
  expose :free_delivery
  expose :free_service_fee
  expose :free_shipping
  expose :percent
  expose :engraving_percent
  expose :description
  expose :reporting_type_id
  expose :minimum_units
  expose :nth_order
  expose :sellable_type
  expose :sellable_ids
  expose :sellable_restriction_excludes
  expose :combine
  expose :starts_at
  expose :expires_at
  expose :restrict_items
  expose :supplier_type
  expose :single_use
  expose :quota
  expose :skip_fraud_check
  expose :nth_order_item
  expose :free_product_id
  expose :free_product_id_nth_count
  expose :exclude_pre_sale
  expose :domain_name
  expose :membership_plan_id
  expose :doorkeeper_application_ids
end
