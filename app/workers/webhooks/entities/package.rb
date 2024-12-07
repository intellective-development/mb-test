# frozen_string_literal: true

module Webhooks
  module Entities
    # Webhooks::Entities::Package
    class Package < Grape::Entity
      expose :carrier
      expose :label_url, as: :labelUrl
      expose :tracking_number, as: :trackingNumber
      expose :tracking_url, as: :trackingUrl
    end
  end
end
