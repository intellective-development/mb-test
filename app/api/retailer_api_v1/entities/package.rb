# frozen_string_literal: true

# Retailer package entity
class RetailerAPIV1::Entities::Package < Grape::Entity
  expose :carrier
  expose :label_url, as: :labelUrl
  expose :tracking_number, as: :trackingNumber
  expose :tracking_url, as: :trackingUrl
end
