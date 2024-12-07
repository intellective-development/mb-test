# frozen_string_literal: true

module BarOS
  module Entities
    module Orders
      # LiquidUser
      class LiquidUser < LiquidBase
        expose :id
        expose :default_shipping_address, with: BarOS::Entities::Orders::LiquidAddress
        expose :email
        expose :first_name
        expose :last_name
        expose :notes do |user|
          user.customer_service_comments.pluck(:note).join(', ')
        end
        expose :tax_exempt, &:tax_exempt?
        expose :sms_subscribed
        expose :email_subscribed
        expose :birth_date
        expose :created_at, format_with: :timestamp
        expose :state

        private

        def birth_date
          object.birth_date.to_s
        end
      end
    end
  end
end
