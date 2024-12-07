# frozen_string_literal: true

# This concern defines methods to return each service accounts
module ServiceAccounts
  extend ActiveSupport::Concern

  included do
    class << self
      def door_dash
        includes(:user).find_by(first_name: 'DoorDash', last_name: 'DeliveryService')
      end

      def cart_wheel
        includes(:user).find_by(first_name: 'CartWheel', last_name: 'DeliveryService')
      end

      def uber
        includes(:user).find_by(first_name: 'Uber', last_name: 'DeliveryService')
      end

      def delivery_solutions
        includes(:user).find_by(first_name: 'DeliverySolutions', last_name: 'DeliveryService')
      end

      def zifty
        includes(:user).find_by(first_name: 'Zifty', last_name: 'DeliveryService')
      end

      def seven_eleven
        includes(:user).find_by(first_name: '7eleven', last_name: 'IntegrationService')
      end

      def specs
        includes(:user).find_by(first_name: 'Specs', last_name: 'IntegrationService')
      end

      def bevmax
        includes(:user).find_by(first_name: 'BevMax', last_name: 'IntegrationService')
      end

      def three_jms
        includes(:user).find_by(first_name: '3JMS', last_name: 'IntegrationService')
      end

      def ship_station
        includes(:user).find_by(first_name: 'ShipStation', last_name: 'IntegrationService')
      end

      def super_admin
        includes(:user).find_by(first_name: 'Super', last_name: 'Admin')
      end
    end
  end
end
