# frozen_string_literal: true

module BarOS
  module Entities
    module Orders
      # LiquidAddress
      class LiquidAddress < LiquidBase
        expose :id
        expose :company
        expose :address1
        expose :address2
        expose :city
        expose :state_name
        expose :zip_code
        expose :latitude, format_with: :force_string
        expose :longitude, format_with: :force_string
        expose :addressable_type
        expose :addressable_id
        expose :country do |address|
          address.country&.name
        end
        expose :country_code, if: ->(object, _options) { object.addressable_type == 'User' } do |address|
          address.country&.abbreviation
        end
        expose :name
        expose :person_first_name, if: ->(object, _options) { object.addressable_type == 'User' } do |address|
          address.addressable.first_name
        end
        expose :person_last_name, if: ->(object, _options) { object.addressable_type == 'User' } do |address|
          address.addressable.last_name
        end
        expose :person_full_name, if: ->(object, _options) { object.addressable_type == 'User' } do |address|
          "#{address.addressable.first_name} #{address.addressable.last_name}"
        end
        expose :phone, &:normalized_phone
        expose :state_code do |address|
          address.state&.abbreviation
        end
      end
    end
  end
end
