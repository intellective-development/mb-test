# frozen_string_literal: true

module BarOS
  module Users
    # Hooks to update data in shopify
    module Hooks
      extend ActiveSupport::Concern

      included do
        after_commit :bar_os_user_update!, on: :update, if: :need_bar_os_user_update?
      end

      def need_bar_os_user_update?
        ENV['KAFKA_KIT_ENABLED'].to_s == 'true' &&
          (sms_subscribed_changed? || email_subscribed_changed?) &&
          account_id &&
          account.liquid_account? &&
          account.storefront.shopify? &&
          !orders.count.zero?
      end

      def bar_os_user_update!
        ::BarOSAPI::Admin::V1::RegisteredAccounts.update(id: user.account_id, request: { timeout: 1 })
      rescue Faraday::Error # rubocop:disable Lint/SuppressedException
      end
    end
  end
end
