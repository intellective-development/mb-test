# frozen_string_literal: true

module Webhooks
  module Entities
    # Webhooks::Entities::Address
    class Address < Grape::Entity
      expose :address1
      expose :address2
      expose :city
      expose :country do |_|
        'USA'
      end
      expose :state_name, as: :state
      expose :zip_code, as: :zip
      expose :latitude
      expose :longitude
    end
  end
end
