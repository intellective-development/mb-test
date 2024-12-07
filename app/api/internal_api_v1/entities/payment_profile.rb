# frozen_string_literal: true

class InternalAPIV1
  module Entities
    # InternalAPIV1::Entities::PaymentProfile
    class PaymentProfile < Grape::Entity
      expose :cc_type
      expose :last_digits
      expose :month, as: :exp_month
      expose :year, as: :exp_year

      expose :address do
        expose :name do |payment_profile|
          payment_profile.address.name
        end
        expose :address1 do |payment_profile|
          payment_profile.address.address1
        end
        expose :address2 do |payment_profile|
          payment_profile.address.address2
        end
        expose :city do |payment_profile|
          payment_profile.address.city
        end
        expose :state do |payment_profile|
          payment_profile.address.state_name
        end
        expose :zip_code do |payment_profile|
          payment_profile.address.zip_code
        end
      end
    end
  end
end
