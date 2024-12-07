# frozen_string_literal: true

class InternalAPIV1
  module Entities
    # InternalAPIV1::Entities::Address
    class Address < Grape::Entity
      expose :id, unless: ->(_object, options) { options[:supplier] }

      expose :name,                   unless: ->(_object, options) { options[:supplier] }
      expose :company,                unless: ->(_object, options) { options[:supplier] }
      expose :address1
      expose :address2
      expose :city
      expose :state_name, as: :state
      expose :zip_code
      expose :phone, unless: ->(_object, options) { !options[:show_phone] && options[:supplier] }
      expose :latitude
      expose :longitude
    end
  end
end
