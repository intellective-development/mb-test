# frozen_string_literal: true

module BarOS
  module Entities
    module Orders
      # LiquidSupplierAddress
      class LiquidSupplierAddress < LiquidBase
        expose :id
        # expose :company
        expose :company do |address, _|
          address.addressable.name
        end
        expose :address1
        expose :address2
        expose :city
        expose :state_name do |address, _|
          address.state&.name
        end
        expose :zip_code
        expose :latitude, format_with: :force_string
        expose :longitude, format_with: :force_string
        expose :addressable_type
        expose :addressable_id
        expose :country do |address|
          address.country&.name
        end
        expose :country_code do |address|
          address.country&.abbreviation
        end
        expose :name
        expose :phone, &:normalized_phone
        expose :state_code do |address|
          address.state&.abbreviation
        end
      end
    end
  end
end
