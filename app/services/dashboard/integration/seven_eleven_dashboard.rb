module Dashboard
  module Integration
    class SevenElevenDashboard
      extend DashboardInterface
      include SevenEleven::ApiMethods
      include SentryNotifiable

      def initialize
        @api = get_integration
      end

      def place_order(shipment)
        submit_req = nil
        checkout_req = nil
        submit = nil
        checkout = nil

        unless shipment.external_shipment_id.nil?
          Rails.logger.error "[7-Eleven] Skipped order placement of shipment #{shipment.id}. 7NOW ID already assigned!"
          return
        end

        checkout_call = checkout_order(shipment)

        order = checkout_call[:order]
        checkout_req = checkout_call[:checkout_req]
        checkout = checkout_call[:checkout]
        item_errors = checkout_call[:item_errors]

        # checkout case: items unavailable
        issues = get_order_items_issues(item_errors)
        unless issues.empty?
          SevenEleven::Notes.add_note(shipment, "-> Could not place shipment order due to:\n#{issues.join("\n")}", true)

          message = "7eleven rejected shipment #{shipment.id} order placement during checkout due to: #{issues.join(', ')}"
          notify_sentry_and_log(SevenEleven::Error::StandardError.new(message),
                                message,
                                { integration: '7eleven', shipment: shipment.id, request: checkout_req, response: checkout })

          return
        end

        # checkout case: issue returned during checkout
        if checkout.body&.status != 'success'
          Integration::SevenEleven::Tags::TagsHelper.add_tag_with_code(shipment, checkout.body&.message&.code)
          raise SevenEleven::Error::StandardError, "7eleven rejected shipment #{shipment.id} order placement during checkout due to: #{checkout.body&.message&.message || 'unknown reason'}", checkout.body&.message&.code
        end

        # no issues during checkout -> submit the order
        complete_order = create_complete_order_object(shipment, order)
        submit_req, submit = @api.submit_order(complete_order, shipment.uuid)

        # case: unknown issue during order submission (incorrect response)
        raise SevenEleven::Error::StandardError, "Could not successfully complete 7eleven shipment #{shipment.id} order submission" if submit.status != 200

        # case: issue returned during order submission
        if submit.body&.status != 'success'
          Integration::SevenEleven::Tags::TagsHelper.add_tag_with_code(shipment, submit.body&.message&.code)
          raise SevenEleven::Error::StandardError, "7eleven rejected submission of shipment #{shipment.id} order: #{submit.body&.message&.message || 'unknown reason'}", submit.body&.message&.code
        end

        seven_now_id = submit.body&.data&.now_order_id
        shipment.external_shipment_id = seven_now_id
        shipment.save if seven_now_id

        Integration::SevenEleven::Tags::TagsHelper.add_tag(shipment, Integration::SevenEleven::Tags::TagsList::SUCCESSFUL)
        SevenEleven::Notes.add_note(shipment, "-> Shipment order placed\nMBID: #{shipment.uuid}\n7NOWID: #{seven_now_id || 'unknown'}")
      rescue StandardError => e
        message = "[7-Eleven] Error when placing order: #{e} #{submit&.body}"
        notify_sentry_and_log(e, message, { integration: '7eleven', shipment: shipment.id, request: submit_req || checkout_req, response: submit || checkout })

        error_details = (submit || checkout)&.body&.message&.message
        note = '-> Error while placing shipment order. You can retry to place the order in MiniAdmin.'
        note += "\nDetails: #{error_details}" unless error_details.nil?
        SevenEleven::Notes.add_note(shipment, note, true)
      end

      def cancel_order(shipment)
        cancel_req = nil
        cancel = nil

        if shipment.external_shipment_id.nil?
          Rails.logger.error "[7-Eleven] Skipped order cancellation of shipment #{shipment.id}. 7NOW ID not assigned!"
          return
        end

        cancel_req, cancel = @api.cancel_order(shipment.uuid)

        # case: success
        if cancel.status == 200 && cancel.body&.status == 'success'
          SevenEleven::Notes.add_note(shipment, '-> Shipment canceled')
        # case: already processed
        elsif cancel.body&.status == 'failed' && cancel.body&.message&.code == '0404'
          SevenEleven::Notes.add_note(shipment, "-> Shipment already processed - can't cancel", true)
        else
          Integration::SevenEleven::Tags::TagsHelper.add_tag(shipment, Integration::SevenEleven::Tags::TagsList::CANCELLATION_ISSUE)
          raise SevenEleven::Error::StandardError, "7eleven order cancel failed for shipment #{shipment.id}"
        end
      rescue StandardError => e
        message = "[7-Eleven] Error when canceling order: #{e} #{cancel&.body}"
        notify_sentry_and_log(e, message, { integration: '7eleven', shipment: shipment.id, request: cancel_req, response: cancel })

        SevenEleven::Notes.add_note(shipment, '-> Error while canceling shipment order')
        raise e
      end

      def change_order_status(shipment, state)
        # do nothing
      end

      def simple_checkout(shipment, explicit_address = nil)
        checkout_call = checkout_order(shipment, explicit_address)

        raise checkout_call[:order_error] unless checkout_call[:order_error].nil?
        raise checkout_call[:item_errors][0] unless checkout_call[:item_errors].empty?

        checkout_call[:checkout]
      end

      def checkout_order(shipment, explicit_address = nil)
        checkout_req = nil
        checkout = nil

        begin
          order = create_checkout_order_object(shipment, explicit_address)

          # NOTE: verify provides payload verification which is obsolete for production use
          # verify = @api.verify_order(order)
          # raise SevenEleven::Error::StandardError, '7eleven order verification failed' if verify.status != 200 || verify.body['status'] != "success"

          checkout_req, checkout = @api.checkout_order(order)
          raise SevenEleven::Error::StandardError, "7eleven order checkout failed for shipment #{shipment.id}" if checkout.status != 200

          order_error = validate_order_issue(shipment, checkout)
          item_errors = validate_order_items(shipment, checkout)
        rescue StandardError => e
          message = "[7-Eleven] Error when checking out order: #{e} #{checkout&.body}"
          notify_sentry_and_log(e, message, { integration: '7eleven', shipment: shipment.id, request: checkout_req, response: checkout })

          SevenEleven::Notes.add_note(shipment, '-> Error while fetching shipment checkout data')
          raise e
        end

        { order: order, checkout_req: checkout_req, checkout: checkout, order_error: order_error, item_errors: item_errors }
      end

      def self.calculate_inline_edits(shipment, sku, quantity, quantity_to_replace)
        order_item = Shared::Helpers::OrderItemHelpers.get_order_item_with_sku(shipment, sku)
        current_supplier = shipment.supplier
        substitution_params = {
          shipment: shipment,
          order_item: order_item,
          sku: sku,
          quantity: quantity,
          quantity_to_replace: quantity_to_replace,
          custom_price: nil, # NOTE: HERE WE CAN SET 7-11's CUSTOM PRICE?
          supplier_id: current_supplier.id
        }
        if quantity.positive?
          create_substitution = SubstitutionService.new(substitution_params)
          substitute_variant = create_substitution.get_substitute_variant
          substitute_order_item = create_substitution.get_substitute_order_item(substitute_variant)
          remaining_order_item = create_substitution.get_remaining_order_item
          substitution = create_substitution.get_substitution(shipment, substitute_order_item, order_item, remaining_order_item)
          substitution.confirm(RegisteredAccount.seven_eleven.user.id, 'off')

          Segment::SendOrderUpdatedEventWorker.perform_async(shipment.order.id, :substitution_created)
        else
          shipment.remove_order_item(order_item, RegisteredAccount.seven_eleven.user.id)

          order_id = shipment.order.id

          Segment::SendOrderUpdatedEventWorker.perform_async(order_id, :item_removed)
          Segment::SendProductsRefundedEventWorker.perform_async(order_id, order_item.id)
        end
      end

      def validate_order_issue(shipment, res)
        if res.body&.status == 'failed'
          error_code = res.body&.message&.code
          error_message = res.body&.message&.message

          # TODO: fix, no shipment is available here. maybe we need that in place_order instead?
          # Integration::SevenEleven::Tags::TagsHelper.add_tag_with_code(shipment, error_code)

          return SevenEleven::Error::StoreUnavailableError.new(error_message, error_code, shipment&.supplier&.id, shipment&.supplier&.display_name) if [Dashboard::Integration::SevenEleven::Error::ErrorCodes::STORE_UNAVAILABLE].include?(error_code)

          if [Dashboard::Integration::SevenEleven::Error::ErrorCodes::INVALID_REQUEST_FORMAT].include?(error_code) &&
             error_message.downcase.include?('item exceed the limit of max')

            return SevenEleven::Error::ExceededItemsLimitError.new(error_message, error_code, error_message[/\d+/])
          end
        end

        nil
      end

      def validate_order_items(shipment, res)
        errors = []

        if res.body&.status == 'failed'
          (res.body&.data&.items || []).each do |i|
            next if i&.available == true

            item = Shared::Helpers::OrderItemHelpers.get_order_item_with_sku(shipment, i&.item_id)

            error_message = i&.availability_message || 'item not available'
            item_id = item&.variant&.id
            item_sku = i&.item_id
            item_name = item&.variant&.name
            item_qty = item&.quantity
            external_name = i&.name
            available_qty = (i&.availableQuantity || 0).positive? ? i&.availableQuantity : nil
            current_price = i&.current_price.nil? ? nil : i.current_price.to_f / 100

            # we are defining error_code ourselves as 7NOW is returning only single error for the whole order

            # default error: limited qty and out of stock
            error_code = Dashboard::Integration::SevenEleven::Error::ErrorCodes::ITEM_UNAVAILABLE

            # alcohol sale restrictions
            error_code = Dashboard::Integration::SevenEleven::Error::ErrorCodes::ITEM_RESTRICTED_SALE_HOURS if error_message.downcase.include?('restricted alcohol sale hours')

            # price mismatch
            error_code = Dashboard::Integration::SevenEleven::Error::ErrorCodes::ITEM_PRICE_MISMATCH unless current_price.nil?

            errors.push(SevenEleven::Error::ItemError.new(
                          error_message,
                          error_code,
                          item_id,
                          item_sku,
                          item_name,
                          item_qty,
                          available_qty,
                          current_price,
                          external_name
                        ))

            Integration::SevenEleven::Tags::TagsHelper.add_tag_with_code(shipment, error_code)
          end
        end

        errors
      end

      private

      def create_checkout_order_object(shipment, explicit_address = nil)
        items = []
        shipment.order_items.each do |i|
          item = SevenEleven::Builder::ItemBuilder.build do |b|
            b.set_sku(i.variant.sku)
            b.set_price(i.variant.original_price)
            b.set_quantity(i.quantity)
          end

          items.push(item)
        end

        # Allow to provide explicit address (eg. for tax/fees calculation)
        address = explicit_address.nil? ? shipment.address : explicit_address

        shipping = SevenEleven::Builder::ShippingBuilder.build do |b|
          b.set_city(address.city)
          b.set_state(address.state_name)
          b.set_zip_code(address.zip_code)
          b.set_street(address.address_lines)
          b.set_geo_position(address.latitude, address.longitude)
        end

        SevenEleven::Builder::OrderBuilder.build do |b|
          b.set_store_id(shipment.supplier.external_supplier_id)

          items.each { |i| b.add_item(i) }

          b.mark_as_delivery
          b.set_shipping_address(shipping)
        end
      end

      def create_payment_details_object(shipment, _order)
        total_amount = shipment&.total_supplier_charge || 0
        gift_card_amount = shipment&.shipment_gift_card_amount.to_f || 0
        promo_amount = (shipment&.shipment_discounts_total.to_f - gift_card_amount).round(2) # all other discounts: promo, deals
        promo_amount = 0 if promo_amount.negative?

        if Feature[:seven_eleven_gift_card_max_fix].enabled?
          # This is the way 7-11 calculates their total amount, and we cannot send discounts greater than this
          discount_ceil = shipment.shipment_sub_total + shipment.delivery_fee + shipment.shipment_amount.bag_fee + shipment.shipment_tip_amount + shipment.shipment_amount.bottle_deposits

          # Discounting credit card payment amount from discount_ceil
          discount_ceil -= total_amount if total_amount.positive?

          # `[discount_ceil - promo_amount, 0].max` is used here to avoid negative values even being not possible to have promo_amount > discount_ceil
          gift_card_amount = [gift_card_amount, [discount_ceil - promo_amount, 0].max].min
        end

        charge = (shipment.charges || [])[0]
        if charge.present?
          payment_profile = charge.payment_profile

          payment_details = SevenEleven::Builder::PaymentDetailsBuilder.build do |b|
            b.set_gateway('braintree')
            b.mark_as_card_payment
            b.mark_as_usd_transaction
            b.set_transaction_id(charge.transaction_id)
            b.set_amount(total_amount)
            b.set_gift_card_amount(gift_card_amount) if gift_card_amount.positive?
            b.set_promo_amount(promo_amount) if promo_amount.positive?
            b.set_cc_brand(payment_profile&.cc_type)
            b.set_cc_first6(payment_profile.bin) unless payment_profile&.bin.nil?
            b.set_cc_last4(payment_profile.last_digits) unless payment_profile&.last_digits.nil?
            b.set_funding(payment_profile&.cc_kind.nil? ? 'unknown' : payment_profile.cc_kind)
          end

          payment_details.validate

          return payment_details
        end

        # TECH-7456: Order's totally covered by gift cards, we only need to send those fields.
        SevenEleven::Builder::PaymentDetailsBuilder.build do |b|
          b.mark_as_usd_transaction
          b.set_transaction_id("MB-#{shipment.uuid}")
          b.set_gift_card_amount(gift_card_amount) if gift_card_amount.positive?
          b.set_promo_amount(promo_amount) if promo_amount.positive?

          if Feature[:disable_tech7456].enabled?
            b.set_gateway('minibar')
            b.mark_as_card_payment
            b.set_amount(total_amount)
            b.set_cc_brand('unknown')
            b.set_cc_first6('000000')
            b.set_cc_last4('0000')
            b.set_funding('minibar')
          end
        end
      end

      def create_user_profile_object(shipment)
        user_profile_name = shipment.address.name.split(' ')
        last_name = shipment.address.name[user_profile_name.first.length + 1..]
        # TECH-5239 - use first name if last name is not available.
        last_name = user_profile_name.first if last_name.nil? || last_name.empty?

        SevenEleven::Builder::UserProfileBuilder.build do |b|
          b.set_first_name(user_profile_name.first)
          b.set_last_name(last_name)
          b.set_phone_number("+1#{shipment.address.phone}")
        end
      end

      def get_payment_auth_code(shipment)
        charge = (shipment.charges || [])[0]
        charge_transition_meta = charge&.last_charge_transition&.metadata
        return charge_transition_meta['processor_authorization_code'] if !charge_transition_meta.nil? && charge_transition_meta.key?('processor_authorization_code')

        'UNKNOWN'
      end

      def create_complete_order_object(shipment, order)
        payment_details = create_payment_details_object(shipment, order)
        payment_auth_code = get_payment_auth_code(shipment)

        user_profile = create_user_profile_object(shipment)

        commission_rate = 6.0
        commission_amount = shipment.sub_total * (commission_rate / 100)

        bag_fee_item = nil
        delivery_fee_item = nil
        bottle_deposits_item = nil
        basket_fee_item = nil

        if shipment.shipment_amount&.bag_fee&.positive?
          bag_fee_item = SevenEleven::Builder::ItemBuilder.build do |i|
            i.set_sku('bag-fee')
            i.set_price(shipment.shipment_amount.bag_fee)
            i.set_name('Bag Fee')
            i.set_quantity(1)
          end
        end

        if shipment.delivery_fee&.positive?
          delivery_fee_item = SevenEleven::Builder::ItemBuilder.build do |i|
            i.set_sku('delivery-fee')
            i.set_price(shipment.delivery_fee)
            i.set_name('Delivery Fee')
            i.set_quantity(1)
          end
        end

        if shipment.shipment_amount&.bottle_deposits&.positive?
          bottle_deposits_item = SevenEleven::Builder::ItemBuilder.build do |i|
            i.set_sku('bottle-deposits')
            i.set_price(shipment.shipment_amount.bottle_deposits)
            i.set_name('Bottle Deposits')
            i.set_quantity(1)
          end
        end

        if Feature[:seven_eleven_bag_fee].enabled?
          basket_fee_item = SevenEleven::Builder::ItemBuilder.build do |i|
            i.set_sku('basket-fee')
            i.set_price(0)
            i.set_name('Basket Fee')
            i.set_quantity(1)
          end
        end

        SevenEleven::Builder::OrderBuilder.build(order) do |b|
          total_fees = 0

          b.set_delivery_note(shipment.order.delivery_notes) if shipment.order.delivery_notes
          b.set_payment_details(payment_details)
          b.set_payment_auth_code(payment_auth_code)
          b.set_tax_total(shipment.tax_total)
          b.set_tip(shipment.shipment_tip_amount) if shipment.shipment_tip_amount.positive?
          b.set_user_profile(user_profile)
          b.set_commission_rate(commission_rate)
          b.set_commission_amount(commission_amount)

          if bag_fee_item.present?
            b.add_fee_item(bag_fee_item)
            total_fees += shipment.shipment_amount.bag_fee.to_f
          end

          if delivery_fee_item.present?
            b.add_fee_item(delivery_fee_item)
            total_fees += shipment.delivery_fee.to_f
          end

          if bottle_deposits_item.present?
            b.add_fee_item(bottle_deposits_item)
            total_fees += shipment.shipment_amount.bottle_deposits.to_f
          end

          b.add_fee_item(basket_fee_item) if basket_fee_item.present?

          b.set_fees(total_fees) if b.order.fee_items&.size&.positive?
        end
      end

      def get_order_items_issues(errors)
        issues = []

        errors.each do |e|
          issue = "Item #{e.item_sku} (#{e.item_name || 'unknown'}): #{e.message}"
          issue += " (available qty: #{e.item_available_qty})" unless e.item_available_qty.nil?
          issue += " $#{e.item_current_price}" unless e.item_current_price.nil?

          issues.push(issue)
        end

        issues
      end
    end
  end
end
