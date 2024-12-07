# frozen_string_literal: true

class InternalAPIV1
  module Entities
    class Storefront < ConsumerAPIV2::Entities::Storefront
      expose :is_liquid
    end
  end
end
