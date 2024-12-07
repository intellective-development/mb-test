# frozen_string_literal: true

# AdminAPIV1::Entities::CnameRecord
class AdminAPIV1::Entities::CnameRecord < Grape::Entity # rubocop:disable Style/ClassAndModuleChildren
  expose :id
  expose :env
  expose :domain
  expose :status
  expose :certificate_arn
  expose :storefront_id
end
