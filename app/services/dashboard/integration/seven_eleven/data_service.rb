module Dashboard
  module Integration
    module SevenEleven
      class DataService
        REDIS_PREFIX = 'SevenElevenDataService'.freeze

        def initialize(shipment)
          @storefront = shipment.order.storefront
          @shipment_data = get_shipment_checkout_data(shipment)
          MetricsClient::Metric.emit('minibar_web.integration.7eleven.success', 1)
        rescue Error::ItemError => e
          if e&.error_code == Error::ErrorCodes::ITEM_PRICE_MISMATCH
            MetricsClient::Metric.emit('minibar_web.integration.7eleven.error.price_changed', 1)
            item_ordered = Variant.find_by(id: e.item_id)
            wrong_price = item_ordered.price
            item_ordered.update(price: e.item_current_price) if Feature['enabled_update_price_from_7eleven_integration'].enabled?
            raise DataService.get_public_error("This store has changed the price of #{e.item_name} from #{wrong_price} to #{e.item_current_price} since you added it to the cart. Please re-add it to your cart in order to complete checkout.", shipment.order.storefront)
          end
          # case: product available in limited qty
          if e&.item_name.present? && e&.item_available_qty&.positive? && e&.item_requested_qty.present?
            MetricsClient::Metric.emit('minibar_web.integration.7eleven.error.limited_qty', 1)
            update_qty_on_hand(e&.item_id, e.item_available_qty) # TECH-7373
            missing_qty = (e.item_requested_qty - e.item_available_qty).to_i
            raise DataService.get_public_error("Only #{e&.item_available_qty} of #{e&.item_requested_qty} #{e&.item_name} products from 7-Eleven are available. Please remove #{missing_qty} item(s) from your cart in order to complete checkout.", shipment.order.storefront)
          end

          # case: product unavailable due to local alcohol sale restrictions
          if !e&.item_name.nil? && e&.error_code == Dashboard::Integration::SevenEleven::Error::ErrorCodes::ITEM_RESTRICTED_SALE_HOURS
            MetricsClient::Metric.emit('minibar_web.integration.7eleven.error.restricted_sale_hours', 1)
            raise DataService.get_public_error("#{e&.item_name} is not available at this time due to local alcohol sale restrictions.", shipment.order.storefront, 'InvalidItem', { itemId: e&.item_id })
          end

          # case: product unavailable (no defined reason)
          if e&.external_name.nil?
            Variant.find_by(id: e&.item_id).tap do |variant| # TECH-7336 remove variant when SevenEleven says unavailable (different than OOS)
              variant.soft_destroy
              variant.reindex_async
            end
          end

          update_qty_on_hand(e&.item_id, 0) # TECH-7373
          unless e&.item_name.nil?
            MetricsClient::Metric.emit('minibar_web.integration.7eleven.error.unavailable.named', 1)
            raise DataService.get_public_error("#{e&.item_name} from your 7-Eleven order is out of stock.", shipment.order.storefront, 'InvalidItem', { itemId: e&.item_id })
          end

          # case: some products are unavailable (fallback when we don't have product name)
          MetricsClient::Metric.emit('minibar_web.integration.7eleven.error.unavailable.unknown', 1)
          raise DataService.get_public_error('Some products in your 7eleven order are not available.', shipment.order.storefront)
        rescue Error::ExceededItemsLimitError => e
          allowed_count = e.allowed_count.nil? ? '' : "(#{e.allowed_count}) "
          MetricsClient::Metric.emit('minibar_web.integration.7eleven.error.limit', 1)
          raise DataService.get_public_error("Please remove one 7-Eleven item from your shopping cart. You've reached their limit for the number of unique items #{allowed_count}allowed per purchase.", shipment.order.storefront)
        rescue Error::StoreUnavailableError => e
          MetricsClient::Metric.emit('minibar_web.integration.7eleven.error.store_unavailable', 1)
          raise DataService.get_public_error("#{e.store_name || '7-Eleven'} is currently closed. Please add items from another store in order to complete checkout.", shipment.order.storefront, 'IntegrationStoreUnavailable', { supplierId: e.supplier_id })
        rescue StandardError => e
          MetricsClient::Metric.emit('minibar_web.integration.7eleven.error.unknown', 1)
          raise DataService.get_public_error('We could not complete your order with 7-Eleven, please try again.', shipment.order.storefront)
        end

        def update_qty_on_hand(variant_id, count_on_hand)
          return unless Feature['enabled_update_count_on_hand_from_7eleven_integration'].enabled?

          Variant.find_by(id: variant_id).tap do |variant|
            variant.inventory.update(count_on_hand: count_on_hand)
          end
        end

        def get_shipment
          OpenStruct.new({
                           "total": convert_from_cents(@shipment_data&.total)
                         })
        end

        def get_bag_fee
          (@shipment_data&.fee_items&.select { |i| i&.fee_type == 'bag_fee' }&.first&.price || 0).to_f / 100
        end

        def get_bottle_fee_from_item(item_sku)
          item = get_item(item_sku)
          item&.fee
        end

        def get_item(item_sku)
          (@shipment_data&.items || []).each do |i|
            if i&.item_id == item_sku
              return OpenStruct.new({
                                      "price": convert_from_cents(calculate_price(i)),
                                      "fee": convert_from_cents(i&.fee || 0),
                                      "tax": convert_from_cents(i&.tax || 0)
                                    })
            end
          end

          raise DataService.get_public_error('We could not checkout your 7eleven order.', @storefront)
        end

        def self.get_public_error(message, storefront, name = nil, extra = nil)
          storefront ||= Storefront.find(Storefront::MINIBAR_ID)

          Dashboard::Integration::Errors::PublicError.new("#{message} If you continue to experience issues, contact #{storefront.business.name} Customer Support at #{storefront.display_support_phone_number}.", name, extra)
        end

        def self.get_shipment_cache_key(shipment)
          items_key = ''
          shipment.order_items.each do |i|
            items_key += ':' unless items_key.empty?
            items_key += "#{i.variant.sku}-#{i.quantity}"
          end

          items_hash = Digest::MD5.hexdigest(items_key)

          "#{REDIS_PREFIX}:#{shipment.id}:#{items_hash}"
        end

        private

        def convert_from_cents(price)
          (price.to_f / 100).to_f.round_at(2)
        end

        def calculate_price(item)
          regular_price = item&.price
          ordered_qty = item&.qty

          discount_per_unit = item&.discount_per_unit
          discount_qty = item&.discount_qty || 0

          # no promos
          return regular_price if discount_per_unit.nil?

          total_discount = discount_per_unit * [discount_qty, ordered_qty].min
          total_price = regular_price * ordered_qty
          total_discounted = total_price - total_discount

          # spread discount across all items
          (total_discounted / ordered_qty).to_i
        end

        def get_shipment_checkout_data(shipment)
          redis_key = DataService.get_shipment_cache_key(shipment)
          cached_data = Redis.current&.get(redis_key)

          # rubocop:disable Security/MarshalLoad
          return Marshal.load(cached_data) unless cached_data.nil?
          # rubocop:enable Security/MarshalLoad

          address = shipment.address
          address ||= shipment.supplier_address
          checkout = Dashboard::Integration::SevenElevenDashboard.new.simple_checkout(shipment, address)
          checkout_data = checkout.body&.data

          Redis.current&.set(redis_key, Marshal.dump(checkout_data).force_encoding('UTF-8'), ex: 450)

          checkout_data
        end
      end
    end
  end
end
