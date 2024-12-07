module Dashboard
  module Integration
    class SpecsDashboard
      extend DashboardInterface
      include Specs::ApiMethods
      include SentryNotifiable

      def initialize
        @api = get_integration
      end

      def self.get_supplier_ids
        supplier_ids = Supplier.where(dashboard_type: Supplier::DashboardType::SPECS).ids
        supplier_ids.concat Supplier.where(delegate_supplier_id: supplier_ids).ids
      end

      def place_order(shipment)
        request = nil
        response = nil

        unless shipment.external_shipment_id.nil?
          Rails.logger.error "[Spec's] Skipped order placement of shipment #{shipment.id}. Spec's Order ID already assigned!"
          return
        end

        payload = create_complete_order_object(shipment)
        request, response = @api.add_order(payload)

        if response&.body&.data&.message&.start_with?('Failed to locate item with primary_upc')
          Specs::Notes.add_note(shipment, "-> #{response&.body&.data&.message} (sku)", true)
          return
        end

        raise Specs::Error::StandardError, "Unknown Spec's response. Could not successfully complete Spec's shipment #{shipment.id} order submission" if response.status != 200

        raise Specs::Error::StandardError, "Could not successfully complete Spec's shipment #{shipment.id} order submission" if response.body&.success != true

        shipment.update(external_shipment_id: response.body&.data&.order_id)

        Specs::Notes.add_note(shipment, '-> Shipment order placed')
      rescue StandardError => e
        message = "[Specs] Error when placing order: #{e} #{response&.body}"
        Specs::Notes.add_note(shipment, '-> Error while placing shipment order.')

        notify_sentry_and_log(e, message, { integration: 'specs', shipment: shipment.id, request: request, response: response })
      end

      def cancel_order(shipment)
        request = nil
        response = nil

        note = 'Shipment canceled'

        request, response = @api.update_order_status('canceled', shipment.uuid)

        if response&.body&.data&.message == 'You cannot update a canceled order'
          Specs::Notes.add_note(shipment, "-> #{note}") if shipment.comments.where("note like '%#{note}%'").none?
          return
        end

        raise Specs::Error::StandardError, "Unknown Spec's response. Could not successfully cancel Spec's shipment #{shipment.id}" if response.status != 200

        raise Specs::Error::StandardError, "Could not successfully cancel Spec's shipment #{shipment.id}" if response.body&.success != true

        Specs::Notes.add_note(shipment, "-> #{note}")
      rescue StandardError => e
        message = "[Specs] Error when canceling order: #{e} #{response&.body}"
        Specs::Notes.add_note(shipment, '-> Error while canceling shipment order.')

        notify_sentry_and_log(e, message, { integration: 'Specs', shipment: shipment.id, request: request, response: response })
      end

      def change_order_status(shipment, state)
        request = nil
        response = nil

        shipment_transition = shipment.shipment_transitions.order(created_at: 'DESC').select { |st| st.to_state == state }
        shipment_transition = shipment_transition[0] if shipment_transition.is_a?(Array)

        notification_status = case state
                              when 'confirmed'
                                'redeliver' if shipment_transition.metadata['redeliver'] == true
                              when 'en_route'
                                'out-for-delivery'
                              when 'delivered'
                                'completed'
                              when 'exception'
                                'pending-returned' if shipment_transition.metadata['type'] == 'failed_delivery'
                              end
        if notification_status.nil?
          Rails.logger.error "[Spec's] change_order_status skipped for Shipment ##{shipment.id} since it's notification_status is nil"
          Rails.logger.error shipment.to_json
          return
        end

        request, response = @api.update_order_status(notification_status, shipment.uuid)

        api_response = response&.body&.data&.message

        if api_response == 'You cannot update a completed order'
          Specs::Notes.add_note(shipment, "-> Error while changing shipment order status: #{api_response}")
          return
        end

        raise Specs::Error::StandardError, "Unknown Spec's response. Could not successfully update Spec's shipment #{shipment.id} status" if response.status != 200

        raise Specs::Error::StandardError, "Could not successfully update Spec's shipment #{shipment.id} status" if response.body&.success != true

        Specs::Notes.add_note(shipment, "-> Delivery failed. Please wait for Spec's confirmation of return before initiating redelivery.") if notification_status == 'pending-returned'

        Specs::Notes.add_note(shipment, "-> Spec's was notified of shipment status change: #{notification_status}.")
      rescue StandardError => e
        message = "[Specs] Error when changing order status: #{e} #{response&.body}"
        Specs::Notes.add_note(shipment, '-> Error while changing shipment order status.')

        notify_sentry_and_log(e, message, { integration: 'specs', shipment: shipment.id, request: request, response: response })
      end

      def self.apply_modification(shipment, order_item, sku, quantity, quantity_to_replace)
        substitution_params = {
          shipment: shipment,
          order_item: order_item,
          sku: sku,
          quantity: quantity,
          quantity_to_replace: quantity_to_replace,
          custom_price: nil,
          supplier_id: shipment.supplier.id
        }
        if quantity.positive?
          create_substitution = SubstitutionService.new(substitution_params)
          substitute_variant = create_substitution.get_substitute_variant
          substitute_order_item = create_substitution.get_substitute_order_item(substitute_variant)
          remaining_order_item = create_substitution.get_remaining_order_item
          substitution = create_substitution.get_substitution(shipment, substitute_order_item, order_item, remaining_order_item)
          substitution.confirm(RegisteredAccount.specs.user.id, 'off')

          Segment::SendOrderUpdatedEventWorker.perform_async(shipment.order.id, :substitution_created)
        else
          shipment.remove_order_item(order_item, RegisteredAccount.specs.user.id)

          order_id = shipment.order.id

          Segment::SendOrderUpdatedEventWorker.perform_async(order_id, :item_removed)
          Segment::SendProductsRefundedEventWorker.perform_async(order_id, order_item.id)
        end
      end

      private

      def create_complete_order_object(shipment)
        tax_rate = nil
        items = []
        shipment.order_items.each do |i|
          item = Specs::Builder::ItemBuilder.build do |b|
            b.set_name(i.variant.original_name || i.variant.name)
            b.set_sku(i.variant.sku)
            b.set_price(i.price)
            b.set_quantity(i.quantity)
            b.mark_as_tax_exempt if i.variant.tax_exempt?
          end

          items.push(item)

          tax_rate ||= i&.effective_tax_percentage
        end

        address = shipment.address
        user_profile_name = address.name.split(' ')

        customer_details = Specs::Builder::CustomerDetailsBuilder.build do |b|
          b.set_first_name(user_profile_name.first)
          b.set_last_name(address.name[user_profile_name.first.length + 1..])
          b.set_email('help@minibardelivery.com')
          b.set_phone('8554870740')
          b.set_street(address.address_lines)
          b.set_city(address.city)
          b.set_state(address.state_name)
          b.set_zip_code(address.zip_code)
        end

        delivery = Specs::Builder::DeliveryBuilder.build do |b|
          b.set_shipping_details(customer_details)
        end

        tax_total = shipment.tax_total
        fees_total = shipment.fees_total

        order_summary = Specs::Builder::OrderSummaryBuilder.build do |b|
          b.set_tax_rate(tax_rate || 0)
          b.set_tax_total(tax_total)
          b.set_total(shipment.total)
          b.set_subtotal(shipment.sub_total)
          b.set_fees_total(fees_total)
        end

        Specs::Builder::OrderBuilder.build do |b|
          b.set_order_id(shipment.uuid)
          b.set_order_number("#{shipment.order.number}-#{shipment.id}")
          items.each { |i| b.add_item(i) }
          b.set_customer_details(customer_details)
          b.set_summary(order_summary)
          b.set_delivery(delivery)
          b.set_store_number(shipment.supplier.external_supplier_id)
          b.set_fulfillment_time(shipment.scheduled_for || Time.current)
          b.set_tip(shipment.shipment_tip_amount) if shipment.shipment_tip_amount.positive?
        end
      end
    end
  end
end
