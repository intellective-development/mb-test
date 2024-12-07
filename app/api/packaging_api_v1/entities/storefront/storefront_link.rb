class PackagingAPIV1::Entities::Storefront::StorefrontLink < Grape::Entity
  expose :name
  expose :area
  expose :url
  expose :link_type
end
