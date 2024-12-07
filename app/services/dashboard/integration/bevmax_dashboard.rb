module Dashboard
  module Integration
    class BevmaxDashboard
      extend DashboardInterface
      include Bevmax::ApiMethods
      include SentryNotifiable

      def initialize
        @api = get_integration
      end

      def self.get_shipment_canceled_key(shipment_id)
        "bevmax_shipment_canceled_#{shipment_id}"
      end

      def self.mark_shipment_canceled(shipment_id)
        Redis.current.set(get_shipment_canceled_key(shipment_id), 'true')
      end

      def self.unmark_shipment_canceled(shipment_id)
        Redis.current.del(get_shipment_canceled_key(shipment_id))
      end

      def self.shipment_marked_as_canceled?(shipment_id)
        Redis.current.exists?(get_shipment_canceled_key(shipment_id))
      end

      def place_order(shipment)
        request = nil
        response = nil

        unless shipment.external_shipment_id.nil?
          Rails.logger.info "[BevmaxDashboard] Skipped order placement of shipment #{shipment.id}. Bevmax's Order ID already assigned!"
          return
        end

        Rails.logger.info "[BevmaxDashboard] Creating order object for shipment #{shipment.id}"
        payload = create_complete_order_object(shipment)
        Rails.logger.info "[BevmaxDashboard] Requesting place_order method for shipment #{shipment.id}"
        request, response = @api.place_order(payload)

        raise Bevmax::Error::UnknownError, "Unknown Bevmax's response. Could not successfully complete Bevmax's shipment #{shipment.id} order submission" if response.status >= 500

        raise Bevmax::Error::UnauthorizedError, "Could not successfully complete Bevmax's shipment #{shipment.id} order submission" if response.status == 401

        raise Bevmax::Error::BadRequestError, "Could not successfully complete Bevmax's shipment #{shipment.id} order submission" unless [200, 201].include?(response.status)

        Rails.logger.info "[BevmaxDashboard] Updating shipment #{shipment.id} with external_shipment_id #{response.body&.orderNumber}"
        shipment.update(external_shipment_id: response.body&.orderNumber)

        Rails.logger.info "[BevmaxDashboard] Adding success order placed note to shipment #{shipment.id}"
        Bevmax::Notes.add_note(shipment, '-> Shipment order placed')

        shipment.confirm! unless shipment.confirmed?
      rescue StandardError => e
        message = "[Bevmax] Error when placing order: #{e} #{response&.body}"
        Bevmax::Notes.add_note(shipment, "-> Error while placing shipment order. #{e}", e.is_a?(Bevmax::Error::UnknownError))

        notify_sentry_and_log(e, message, { integration: 'Bevmax', shipment: shipment.id, request: request, response: response })
      end

      def cancel_order(shipment)
        req = nil
        res = nil

        if shipment.external_shipment_id.nil?
          Rails.logger.info "[Bevmax] Skipped order cancellation of shipment #{shipment.id}. Bevmax ID not assigned!"
          return
        end

        if !BevmaxDashboard.shipment_marked_as_canceled?(shipment.id)
          Rails.logger.info '[BevmaxDashboard] Requesting cancel_order method'
          req, res = @api.cancel_order(shipment.external_shipment_id)

          if res.status == 200
            Bevmax::Notes.add_note(shipment, '-> Shipment canceled')
          elsif res.body.include?('Order not found')
            Bevmax::Notes.add_note(shipment, '-> Shipment canceled (already canceled)')
            raise Bevmax::Error::OrderNotFoundError, "Order cancel failed for shipment #{shipment.id}: #{res.body}"
          else
            raise Bevmax::Error::StandardError, "Order cancel failed for shipment #{shipment.id}: #{res.body}"
          end
        else
          BevmaxDashboard.unmark_shipment_canceled(shipment.id)
        end
      rescue StandardError => e
        Rails.logger.error "[Bevmax] Error when canceling order: #{e} #{res&.body}"
        Bevmax::Notes.add_note(shipment, "-> Error while cancelling shipment order: #{e} #{res&.body}")

        unless e.is_a?(Bevmax::Error::OrderNotFoundError)
          notify_sentry_and_log(e,
                                "Exception: #{e}",
                                { integration: 'Bevmax', shipment: shipment.id, request: req, response: res })
          raise e
        end
      end

      def change_order_status(shipment, state)
        # Do nothing
      end

      private

      def create_complete_order_object(shipment)
        items = []

        shipment.order_items.each do |i|
          item = Bevmax::Builder::ItemBuilder.build do |b|
            b.set_sku(i.variant.sku)
            b.set_price(i.price)
            b.set_quantity(i.quantity)
            b.set_tax_exempt(i.tax_charge)
            b.set_engraving(i.item_options) if i.item_options&.type == 'EngravingOptions'
          end

          items.push(item)
        end

        ship_address = shipment.order.ship_address
        amount = shipment.shipment_amount
        gift_detail = shipment.order.gift_detail.presence

        Bevmax::Builder::OrderBuilder.build do |b|
          b.set_order_id(shipment.uuid)
          b.set_order_number("#{shipment.order.number}-#{shipment.id.to_s[-2..]}")
          b.set_store_number(shipment.supplier.external_supplier_id)
          b.set_tip(shipment.shipment_tip_amount) if shipment.shipment_tip_amount.positive?
          b.set_bill_to(build_address(ship_address))
          b.set_ship_to(build_address(ship_address))
          b.set_gift_detail(gift_detail) if gift_detail
          b.set_delivery_notes(shipment.order.delivery_notes) unless shipment.order.delivery_notes.nil?
          b.set_shipping_cost(amount.shipping_charges)
          b.set_total_discount(amount.discounts_total)
          b.set_total_tax(amount.order_items_tax)
          b.set_total_amount(amount.total_before_coupon_applied)

          b.set_business(shipment.order.storefront.business)

          items.each { |i| b.add_item(i) }
        end
      end

      def build_address(address)
        Bevmax::Builder::AddressBuilder.build do |b|
          b.set_name(address.name)
          b.set_email(address.email)
          b.set_phone(address.phone)
          b.set_address1(address.address1)
          b.set_address2(address.address2) unless address.address2.nil?
          b.set_city(address.city)
          b.set_state(address.state)
          b.set_country(address.country)
          b.set_zip_code(address.zip_code)
        end
      end
    end
  end
end
