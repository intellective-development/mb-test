# frozen_string_literal: true

class ConsumerAPIV2::Entities::StorefrontLink < Grape::Entity
  expose :id
  expose :name
  expose :area
  expose :url
  expose :link_type
  expose :storefront, with: ConsumerAPIV2::Entities::Storefront
end
