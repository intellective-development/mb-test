# frozen_string_literal: true

module BarOS
  module Orders
    # Hooks
    module Hooks
      extend ActiveSupport::Concern

      SFCC_KEYS = %w[id storefront_cart_id storefront_uuid storefront_id].freeze
      KEYS = %w[
        active
        allow_substitution
        bill_address_id
        birthdate
        button_referrer_token
        cancelled_at
        cart_id
        client
        completed_at
        confirmed_at
        coupon_id
        courier
        delivery_notes
        delivery_service_order
        device_udid
        doorkeeper_application_id
        email
        finalized_at
        fraud_reported_at
        fraud_score
        gift_detail_id
        id
        ip_address
        ip_geolocation
        membership_id
        membership_plan_id
        metadata
        number
        payment_profile_id
        pickup_detail_id
        platform
        scheduled_for
        ship_address_id
        shoprunner_token
        state
        storefront_cart_id
        storefront_id
        storefront_uuid
        subscription_id
        tag_list
        tip_amount
        trak_id
        user_id
        visit_id
      ].freeze

      KAFKA_ECP_PROVIDER_ACTIONS = {
        # update_shipments can be removed
        non_endemic: %i[
          canceled
          finalize
          update_line_items
          update
          update_shipments
          paid
          partially_fulfilled
          fulfilled
        ],
        sfcc: [:finalize]
      }.freeze

      included do
        after_commit :bar_os_order_send!, unless: :bar_os_order_skip?
      end

      def fulfillment_status
        statuses = shipments.loaded? ? shipments.map(&:state) : shipments.pluck(:state)
        return :fulfilled if statuses.present? && (statuses - %w[en_route delivered]).blank?

        partially_fulfilled =
          (statuses & %w[pending confirmed]).present? && (statuses & %w[en_route delivered]).present?
        return :partially_fulfilled if partially_fulfilled

        nil
      end

      def bar_os_order_skip_update?
        # Because we manually call another actions and don't wanna send update and then specific action
        state_changed? && %w[canceled placed].include?(state)
      end

      def bar_os_order_skip?(action = :update)
        provider = storefront.ecp_provider&.to_sym
        provider = :non_endemic if provider == :shopify
        ENV['KAFKA_KIT_ENABLED'].to_s != 'true' || # disable at all
          storefront.default_storefront? || # ignore minibar storefront
          # only %w[canceled confirmed delivered paid scheduled verifying placed].freeze
          !::Order::FINISHED_STATES.include?(state) ||
          !KAFKA_ECP_PROVIDER_ACTIONS[provider]&.index(action.to_sym) # only send specific action by ecp_provider
      end

      def bar_os_order_send!(action = :update, force: false)
        return if bar_os_order_skip?(action) ||
                  (action == :update && bar_os_order_skip_update?) ||
                  (!force && action == :update && !bar_os_order_changed?(KEYS))

        params = bar_os_order_params
        ::BarOSAPI::Admin::V1::Orders.create(id: id, action: action, params: params, request: { timeout: 2 })
        true
      rescue Faraday::Error # rubocop:disable Lint/SuppressedException
      end

      def bar_os_order_changed?(keys = [])
        changed_keys = previous_changes.keys
        return changed_keys.count.positive? if keys.empty?

        (changed_keys & keys).count.positive?
      end

      def bar_os_order_params
        if storefront.sfcc?
          return attributes.slice(*SFCC_KEYS).merge(
            storefront_account_id: account.storefront_account_id,
            shipping_total: shipping_charges,
            order_total: total_taxed_amount,
            order_number: number
          )
        end

        current_state_once([self] + shipments) do
          ::BarOS::Entities::Orders::LiquidOrder.represent(self).as_json
        end
      end

      def current_state_once(objects)
        objects.map do |object|
          object.instance_eval { define_singleton_method(:current_state) { |*args| @current_state ||= super(*args) } }
        end
        result = yield
        objects.map { |object| object.instance_eval { singleton_class.send(:remove_method, :current_state) } }
        result
      end
    end
  end
end
