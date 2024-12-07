module Dashboard
  module Integration
    class ThreeJMSDashboard
      extend DashboardInterface
      include ThreeJMS::ApiMethods
      include SentryNotifiable

      CANCELABLE_STATUSES = %w[new_order action_req confirmed printed].freeze
      CANCELED_STATUSES = %w[canceled].freeze

      def initialize(supplier)
        @api = get_integration(supplier)
      end

      def self.update_order_items(shipment)
        return unless shipment.effective_supplier.dashboard_type == Supplier::DashboardType::THREE_JMS

        dashboard = ThreeJMSDashboard.new(shipment.effective_supplier)
        dashboard.update_order(shipment)
      end

      def self.update_order_address(shipment)
        return unless shipment.effective_supplier.dashboard_type == Supplier::DashboardType::THREE_JMS

        dashboard = ThreeJMSDashboard.new(shipment.effective_supplier)
        dashboard.update_order(shipment)
      end

      def self.get_shipment_canceled_key(shipment_id, supplier_id)
        "3jms_shipment_canceled_#{supplier_id}_#{shipment_id}"
      end

      def self.mark_shipment_canceled(shipment_id, supplier_id)
        expire_in = 1.day.to_i
        Redis.current.set(get_shipment_canceled_key(shipment_id, supplier_id), 'true', ex: expire_in)
      end

      def self.unmark_shipment_canceled(shipment_id, supplier_id)
        Redis.current.del(get_shipment_canceled_key(shipment_id, supplier_id))
      end

      def self.shipment_marked_as_canceled?(shipment_id, supplier_id)
        Redis.current.get(get_shipment_canceled_key(shipment_id, supplier_id)).present?
      end

      def place_order(shipment)
        request = nil
        response = nil

        unless shipment.external_shipment_id.nil?
          # If the pre-sale or back-order was already placed and came into exception, we need to continue the order
          # It's needed until we have the update payment profile links working
          return continue_order(shipment) unless shipment.customer_placement_standard? && shipment.shipment_transitions[-2]&.to_state == 'exception'

          Rails.logger.info "[3JMSDashboard] Skipped order placement of shipment #{shipment.id}. 3JMS Order ID already assigned!"
          return
        end

        Rails.logger.info "[3JMSDashboard] Creating order object for shipment #{shipment.id}"
        payload = create_complete_order_object(shipment)

        return if order_already_placed?(shipment)

        Rails.logger.info "[3JMSDashboard] Requesting place_order method for shipment #{shipment.id}"
        request, response = @api.place_order(payload)

        raise ThreeJMS::Error::UnknownError, "Unknown 3JMS response. Could not successfully complete 3JMS shipment #{shipment.id} order submission" if response.status == 500

        raise ThreeJMS::Error::UnauthorizedError, "Could not successfully complete 3JMS shipment #{shipment.id} order submission" if response.status == 401

        raise ThreeJMS::Error::BadRequestError, "Could not successfully complete 3JMS shipment #{shipment.id} order submission" unless [200, 201].include?(response.status)

        Rails.logger.info "[3JMSDashboard] Updating shipment #{shipment.id} with external_shipment_id #{response.body[:retailer_order_id]}"

        shipment.update(external_shipment_id: response.body[:retailer_order_id])

        Rails.logger.info "[3JMSDashboard] Adding success order placed note to shipment #{shipment.id}"
        ThreeJMS::Notes.add_note(shipment, '-> Shipment order placed')

        shipment.confirm! if shipment.customer_placement_standard? && !shipment.confirmed?
      rescue StandardError => e
        message = "[3JMSDashboard] Error when placing order: #{e} #{response&.body}"
        notify_sentry_and_log(e, message, { integration: '3JMS', shipment: shipment.id, request: request, response: response })

        ThreeJMS::Notes.add_note(shipment, '-> Error while placing shipment order.', e.is_a?(ThreeJMS::Error::UnknownError))
      end

      def cancel_order(shipment)
        req = nil
        res = nil

        if shipment.external_shipment_id.nil?
          Rails.logger.info "[3JMSDashboard] Skipped order cancellation of shipment #{shipment.id}. 3JMS ID not assigned!"
          return
        end

        three_jms_status = get_3jms_order_status(shipment)

        if CANCELED_STATUSES.include?(three_jms_status)
          ThreeJMS::Notes.add_note(shipment, '-> Shipment canceled (already cancelled)') unless ThreeJMSDashboard.shipment_marked_as_canceled?(shipment.id, shipment.supplier_id)
          return
        end

        unless order_can_be_canceled?(three_jms_status)
          ThreeJMS::Notes.add_note(shipment, "-> Shipment couldn't be canceled cause its status is #{three_jms_status}")
          return
        end

        Rails.logger.info '[3JMSDashboard] Requesting cancel_order method'
        req, res = @api.cancel_order(shipment.external_shipment_id)

        # case: success
        if res.status == 200
          ThreeJMSDashboard.mark_shipment_canceled(shipment.id, shipment.supplier_id)
          ThreeJMS::Notes.add_note(shipment, '-> Shipment canceled')
          # case: already processed
        else
          raise ThreeJMS::Error::StandardError, "Order cancel failed for shipment #{shipment.id}: #{res.body}"
        end
      rescue StandardError => e
        ThreeJMS::Notes.add_note(shipment, "-> Error while cancelling shipment order: #{e} #{res&.body}")

        message = "[3JMSDashboard] Error when canceling order: #{e} #{res&.body}"
        notify_sentry_and_log(e, message, { integration: '3JMS', shipment: shipment.id, request: req, response: res })
      end

      def update_order(shipment)
        request = nil
        response = nil

        if shipment.external_shipment_id.nil?
          Rails.logger.info "[3JMSDashboard] Skipped order update of shipment #{shipment.id}. 3JMS ID not assigned!"
          return
        end

        Rails.logger.info "[3JMSDashboard] Creating order object for shipment #{shipment.id}"
        payload = create_complete_order_object(shipment)
        Rails.logger.info "[3JMSDashboard] Requesting update_order method for shipment #{shipment.id}"
        request, response = @api.update_order(payload)

        raise ThreeJMS::Error::UnknownError, "Unknown 3JMS response. Could not successfully complete 3JMS shipment #{shipment.id} order update" if response.status == 500

        raise ThreeJMS::Error::UnauthorizedError, "Could not successfully complete 3JMS shipment #{shipment.id} order update" if response.status == 401

        raise ThreeJMS::Error::BadRequestError, "Could not successfully complete 3JMS shipment #{shipment.id} order update" unless [200, 201].include?(response.status)

        Rails.logger.info "[3JMSDashboard] Adding success order updated note to shipment #{shipment.id}"
        ThreeJMS::Notes.add_note(shipment, '-> Shipment order updated')
      rescue StandardError => e
        message = "[3JMSDashboard] Error when updating order: #{e} #{response&.body}"
        notify_sentry_and_log(e, message, { integration: '3JMS', shipment: shipment.id, request: request, response: response })

        ThreeJMS::Notes.add_note(shipment, '-> Error while updating shipment order.', e.is_a?(ThreeJMS::Error::UnknownError))
      end

      def hold_order(shipment)
        req = nil
        res = nil

        if shipment.external_shipment_id.nil?
          Rails.logger.info "[3JMSDashboard] Skipped change order status for shipment #{shipment.id}. 3JMS ID not assigned!"
          return
        end

        Rails.logger.info '[3JMSDashboard] Requesting on_hold_order method'
        req, res = @api.update_order_status(shipment.external_shipment_id, 'action_req', 'Do Not Ship Yet')

        if [200, 201].include?(res.status)
          ThreeJMSDashboard.mark_shipment_canceled(shipment.id, shipment.supplier_id)
          ThreeJMS::Notes.add_note(shipment, '-> Shipment put on hold')
        else
          raise ThreeJMS::Error::StandardError, "Hold order failed for shipment #{shipment.id}: #{res.body}"
        end
      rescue StandardError => e
        message = "[3JMSDashboard] Error when putting order on hold: #{e} #{res&.body}"
        notify_sentry_and_log(e, message, { integration: '3JMS', shipment: shipment.id, request: req, response: res })

        ThreeJMS::Notes.add_note(shipment, "-> Error when putting order on hold: #{e} #{res&.body}")
        raise e
      end

      def continue_order(shipment)
        req = nil
        res = nil

        if shipment.external_shipment_id.nil?
          Rails.logger.info "[3JMSDashboard] Skipped change order status for shipment #{shipment.id}. 3JMS ID not assigned!"
          return
        end

        Rails.logger.info '[3JMSDashboard] Requesting continue_order method'
        req, res = @api.update_order_status(shipment.external_shipment_id, 'new_order')

        if [200, 201].include?(res.status)
          ThreeJMSDashboard.mark_shipment_canceled(shipment.id, shipment.supplier_id)
          ThreeJMS::Notes.add_note(shipment, '-> Shipment continued')
        else
          raise ThreeJMS::Error::StandardError, "Continue order failed for shipment #{shipment.id}: #{res.body}"
        end
      rescue StandardError => e
        message = "[3JMSDashboard] Error when continuing order: #{e} #{res&.body}"
        notify_sentry_and_log(e, message, { integration: '3JMS', shipment: shipment.id, request: req, response: res })

        ThreeJMS::Notes.add_note(shipment, "-> Error when continuing order: #{e} #{res&.body}")
        raise e
      end

      def change_order_status(shipment, state)
        continue_order(shipment) if !shipment.customer_placement_standard? && state == 'ready_to_ship' && (shipment.shipment_transitions[-2]&.to_state == 'exception')
      end

      # Sends a comment to 3JMS for an specific shipment
      # @param [Shipment] shipment
      # @param [Comment] comment
      def send_comment(shipment, comment)
        req = nil
        res = nil

        if shipment.external_shipment_id.nil?
          Rails.logger.info "[3JMSDashboard] Skipped order comment of shipment #{shipment.id}. 3JMS ID not assigned!"
          return
        end

        builder = ThreeJMS::Builder::CommentBuilder.new
        builder.set_note(comment.note)
        builder.set_user(comment.user.name) if comment.user.present?
        builder.set_file(comment.file_url) if comment.file_url.present?

        Rails.logger.info '[3JMSDashboard] Send comment method'
        req, res = @api.send_comment(shipment.external_shipment_id, builder.to_s)

        raise ThreeJMS::Error::StandardError, "Send comment failed for shipment #{shipment.id}: #{res.body}" unless [200, 201].include?(res.status)
      rescue StandardError => e
        message = "[3JMSDashboard] Error: #{e}"
        notify_sentry_and_log(e, message, { integration: '3JMS', shipment: shipment.id, request: req, response: res })

        ThreeJMS::Notes.add_note(shipment, "-> Error: #{e}")
        raise e
      end

      private

      def get_external_order_id(shipment)
        "#{shipment.order.number}_#{shipment.id}"
      end

      def get_3jms_order_status(shipment)
        @api.get_3jms_order_status(get_external_order_id(shipment))
      end

      def order_already_placed?(shipment)
        @api.get_3jms_order_id(get_external_order_id(shipment)).present?
      end

      def order_can_be_canceled?(shipment_status)
        CANCELABLE_STATUSES.include?(shipment_status)
      end

      def create_complete_order_object(shipment)
        items = []

        shipment.order_items.each do |i|
          item = ThreeJMS::Builder::ItemBuilder.build do |b|
            b.set_sku(i.variant.sku)
            b.set_name("#{i.variant.product_size_grouping&.name} - #{i.variant.item_volume}")
            b.set_quantity(i.quantity)
            b.set_price(i.price)
            b.set_engraving(i.item_options) if i.item_options&.type == 'EngravingOptions'
          end

          items.push(item)
        end

        ship_address = shipment.order.ship_address

        ThreeJMS::Builder::OrderBuilder.build do |b|
          b.set_order_id("#{shipment.order.number}_#{shipment.id}")
          b.set_brand(shipment.order.storefront.threejms_brand) unless shipment.order.storefront.threejms_brand.nil?
          b.set_email(shipment.order.email)
          b.set_phone(get_phone(shipment.order))
          b.set_ship_to(build_address(ship_address))
          b.set_order_type(shipment.customer_placement)
          b.set_qr_code(Order::CreateTrackingQrCodeService.new(order_id: shipment.order.id).qr_url)
          b.set_gift_detail(shipment.order.gift_detail) unless shipment.order.gift_detail.nil?

          items.each { |i| b.add_item(i) }
        end
      end

      def build_address(address)
        ThreeJMS::Builder::AddressBuilder.build do |b|
          b.set_name(address.name)
          b.set_address1(address.address1)
          b.set_address2(address.address2)
          b.set_city(address.city)
          b.set_state(address.state)
          b.set_company(address.company)
          b.set_country(address.country)
          b.set_zip_code(address.zip_code)
        end
      end

      def get_phone(order)
        phone = order.gift_detail&.recipient_phone
        phone = order.ship_address&.phone if phone.blank?
        phone = order.bill_address&.phone if phone.blank?
        phone
      end
    end
  end
end
