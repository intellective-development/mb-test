# frozen_string_literal: true

module Dashboard
  module Integration
    # ShipStationDashboard is a class that implements the DashboardInterface for ShipStation Integrations
    class ShipStationDashboard
      extend DashboardInterface
      include ShipStation::ApiMethods
      include SentryNotifiable

      CANCELABLE_STATUSES = %w[awaiting_payment awaiting_shipment on_hold].freeze
      CANCELED_STATUSES = %w[cancelled].freeze

      def initialize(supplier)
        @api = get_integration(supplier)
      end

      def self.get_shipment_canceled_key(shipment_id, supplier_id)
        "ship_station_shipment_canceled_#{supplier_id}_#{shipment_id}"
      end

      def self.get_shipment_placed_key(shipment_id, supplier_id)
        "ship_station_shipment_placed_#{supplier_id}_#{shipment_id}"
      end

      def self.mark_shipment_canceled(shipment_id, supplier_id)
        expire_in = 1.day.to_i
        Redis.current.set(get_shipment_canceled_key(shipment_id, supplier_id), 'true', ex: expire_in)
      end

      def self.mark_shipment_placed(shipment_id, supplier_id)
        expire_in = 1.day.to_i
        Redis.current.set(get_shipment_placed_key(shipment_id, supplier_id), 'true', ex: expire_in)
      end

      def self.unmark_shipment_canceled(shipment_id, supplier_id)
        Redis.current.del(get_shipment_canceled_key(shipment_id, supplier_id))
      end

      def self.unmark_shipment_placed(shipment_id, supplier_id)
        Redis.current.del(get_shipment_placed_key(shipment_id, supplier_id))
      end

      def self.shipment_marked_as_canceled?(shipment_id, supplier_id)
        Redis.current.get(get_shipment_canceled_key(shipment_id, supplier_id)).present?
      end

      def self.shipment_marked_as_placed?(shipment_id, supplier_id)
        Redis.current.get(get_shipment_placed_key(shipment_id, supplier_id)).present?
      end

      def place_order(shipment)
        request = nil
        response = nil

        if ShipStationDashboard.shipment_marked_as_placed?(shipment.id, shipment.supplier_id)
          Rails.logger.info "[ShipStation Dashboard] Skipped order placement of shipment #{shipment.id}. ShipStation request has already be sent!"
          return
        end

        if shipment.external_shipment_id.present?
          Rails.logger.info "[ShipStation Dashboard] Skipped order placement of shipment #{shipment.id}. ShipStation Order ID already assigned!"
          return
        end

        ShipStationDashboard.mark_shipment_placed(shipment.id, shipment.supplier_id)

        Rails.logger.info "[ShipStation Dashboard] Creating order object for shipment #{shipment.id}"
        order_object = create_complete_order_object(shipment)

        if Feature[:shipstation_order_placement_check].enabled?
          existing_order = @api.get_order_by_order_number(order_object.order_number, shipment.id)
          if existing_order.present?
            shipment.update(external_shipment_id: existing_order['orderId'])
            Rails.logger.info "[ShipStation Dashboard] Skipped order placement of shipment #{shipment.id}. Order already placed in ShipStation with orderId #{existing_order['orderId']}!"
            return
          end
        end

        Rails.logger.info "[ShipStation Dashboard] Requesting place_order method for shipment #{shipment.id}"
        request, response = @api.place_order(order_object)

        handle_response_errors(response, shipment.id, 'order submission')

        external_id = response.try(:body).try(:[], :orderId)
        Rails.logger.info "[ShipStation Dashboard] Updating shipment #{shipment.id} with external_shipment_id #{external_id}"
        shipment.update(external_shipment_id: external_id)

        Rails.logger.info "[ShipStation Dashboard] Adding success order placed note to shipment #{shipment.id}"
        ShipStation::Notes.add_note(shipment, '-> Shipment order placed')

        shipment.confirm! if shipment.can_transition_to?(:confirmed)
      rescue ShipStation::Errors::RateLimitError => e
        ShipStationDashboard.unmark_shipment_placed(shipment.id, shipment.supplier_id)
        raise e
      rescue StandardError => e
        ShipStationDashboard.unmark_shipment_placed(shipment.id, shipment.supplier_id)
        message = "[ShipStation Dashboard] Error when placing order: #{e} #{response&.body}"
        notify_sentry_and_log(e, message, { integration: 'ShipStation', shipment: shipment.id, request: request, response: response })

        ShipStation::Notes.add_note(shipment, '-> Error while placing shipment order.', critical: e.is_a?(ShipStation::Errors::UnknownError) || e.is_a?(ShipStation::Errors::BadRequestError))
      end

      def cancel_order(shipment)
        request = nil
        response = nil

        if shipment.external_shipment_id.nil?
          Rails.logger.info "[ShipStation Dashboard] Skipped order cancellation of shipment #{shipment.id}. ShipStation ID not assigned!"
          return
        end

        return if ShipStationDashboard.shipment_marked_as_canceled?(shipment.id, shipment.supplier_id)

        ship_station_status = @api.get_order_status(shipment.external_shipment_id)

        if CANCELED_STATUSES.include?(ship_station_status)
          ShipStation::Notes.add_note(shipment, '-> Shipment canceled (already cancelled)')
          return
        end

        unless order_can_be_canceled?(ship_station_status)
          ShipStation::Notes.add_note(shipment, "-> Shipment couldn't be canceled cause its status is #{ship_station_status}")
          return
        end

        Rails.logger.info '[ShipStation Dashboard] Requesting cancel_order method'
        order_object = create_complete_order_object(shipment)

        request, response = @api.cancel_order(order_object)

        handle_response_errors(response, shipment.id, 'order cancellation')

        # case: success
        ShipStationDashboard.mark_shipment_canceled(shipment.id, shipment.supplier_id)
        ShipStation::Notes.add_note(shipment, '-> Shipment canceled')
      rescue ShipStation::Errors::RateLimitError
        raise
      rescue StandardError => e
        ShipStation::Notes.add_note(shipment, "-> Error while cancelling shipment order: #{e} #{response&.body}", critical: e.is_a?(ShipStation::Errors::UnknownError) || e.is_a?(ShipStation::Errors::BadRequestError))

        message = "[ShipStation Dashboard] Error when canceling order: #{e} #{response&.body}"
        notify_sentry_and_log(e, message, { integration: 'ShipStation', shipment: shipment.id, request: request, response: response })
      end

      def change_order_status(_shipment, _state)
        # not implemented
      end

      def get_webhook_resource(resource_url)
        response = @api.get_webhook_resource_content(resource_url)

        handle_response_errors(response, nil, 'webhook resource retrieval')

        response
      end

      private

      def handle_response_errors(response, shipment_id, action)
        raise ShipStation::Errors::UnknownError.new(shipment_id, action, response.body) if response.status == 500

        raise ShipStation::Errors::UnauthorizedError.new(shipment_id, action, response.body) if response.status == 401

        raise ShipStation::Errors::BadRequestError.new(shipment_id, action, response.body) unless [200, 201].include?(response.status)
      end

      def order_can_be_canceled?(status)
        CANCELABLE_STATUSES.include?(status)
      end

      def create_complete_order_object(shipment)
        items = []

        shipment.order_items.each do |i|
          item = ShipStation::Builders::ItemBuilder.build do |b|
            b.with_sku(i.variant.sku)
            b.with_name(i.variant.name)
            b.with_quantity(i.quantity)
            b.with_price(i.price)
            b.with_engraving(i.item_options) if i.item_options&.type == 'EngravingOptions'
          end

          items.push(item)
        end

        ship_address = shipment.order.ship_address

        ShipStation::Builders::OrderBuilder.build do |b|
          b.with_order_id(external_shipment_id(shipment))
          b.with_order_number(shipment.order.number)
          b.with_order_date(shipment.created_at)
          b.with_delivery_notes(shipment.order.delivery_notes) if shipment.order.delivery_notes.present?
          b.with_total_amount(shipment.shipment_amount.total_before_coupon_applied)
          b.with_shipping_fee(shipment.shipping_fee)
          b.with_tax_amount(shipment.shipment_amount.taxed_amount)
          b.with_ship_to(build_address(ship_address))
          b.with_bill_to(build_address(ship_address))
          b.with_gift_detail(shipment.order.gift_detail) unless shipment.order.gift_detail.nil?
          b.with_storefront_name(shipment.order.storefront.name)
          b.with_store_id(shipment.supplier.external_supplier_id) if shipment.supplier.external_supplier_id.present?

          items.each { |i| b.add_item(i) }
        end
      end

      def external_shipment_id(shipment)
        "#{shipment.order.number}_#{shipment.id}"
      end

      def build_address(address)
        ShipStation::Builders::AddressBuilder.build do |b|
          b.with_name(address.name)
          b.with_address1(address.address1)
          b.with_address2(address.address2)
          b.with_city(address.city)
          b.with_state(address.state)
          b.with_company(address.company) if address.company.present?
          b.with_phone(address.phone) if address.phone.present?
          b.with_country(address.country)
          b.with_zip_code(address.zip_code)
        end
      end
    end
  end
end
