# frozen_string_literal: true

# rubocop:disable Style/ClassAndModuleChildren
class ConsumerAPIV2::Entities::Passwordless::Start < Grape::Entity
  expose :login_type
  expose :login_providers, with: ConsumerAPIV2::Entities::LoginProvider
end
# rubocop:enable Style/ClassAndModuleChildren
