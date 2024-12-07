# frozen_string_literal: true

class InternalAPIV1
  # InternalAPIV1::CheckoutEndpoint
  class CheckoutEndpoint < InternalAPIV1
    format :json

    helpers do
      def find_or_create_variant(item:, supplier:, product:)
        # Common update attributes for all cases
        update_attributes = {
          price: item[:unitPrice].to_f / 100,
          name: item[:name],
          liquid_id: item[:liquidId],
          original_item_volume: item[:size],
          supplier: supplier,
          product: product,
          product_active: true,
          liquid: true,
          product_grouping_id: product.product_grouping_id,
          original_name: item[:name]
        }

        # First check if exact ID + supplier combo exists (most authoritative match)
        primary_supplier_variant = Variant
                                     .joins(:product)
                                     .where(id: item[:legacyVariantId], supplier_id: item[:selectedLegacySupplierId])
                                     .first

        if primary_supplier_variant
          primary_supplier_variant.update!(update_attributes)
          return primary_supplier_variant
        end

        # Create unique SKU with UPC and retailer
        sku = "#{item[:variantId]}_#{item[:fulfillmentId]}"

        # Second check if SKU + supplier combo exists
        existing_variant = Variant
                             .where(sku: sku, supplier_id: supplier.id)
                             .first
        if existing_variant
          existing_variant.update!(update_attributes)
          return existing_variant
        end

        # Then try to find variant by legacy ID
        base_variant = Variant
                         .joins(:product)
                         .where(id: item[:legacyVariantId])
                         .first

        if base_variant && base_variant.supplier_id == supplier.id
          base_variant.update!(update_attributes)
          return base_variant
        end

        # Wrap creation in transaction to ensure data consistency
        ActiveRecord::Base.transaction do
          # Create variant first with deferred inventory association
          variant_attributes = if base_variant
                                 {
                                   **update_attributes,
                                   sku: sku,
                                   sale_price: 0,
                                   protected: false,
                                   case_eligible: false,
                                   tax_exempt: false,
                                   frozen_inventory: false,
                                   custom_promo: nil,
                                   options_type: base_variant.options_type,
                                   external_brand_key: base_variant.external_brand_key
                                 }
                               else
                                 {
                                   **update_attributes,
                                   sku: sku,
                                   sale_price: 0,
                                   protected: false,
                                   case_eligible: false,
                                   tax_exempt: false,
                                   frozen_inventory: false,
                                   custom_promo: nil,
                                   options_type: :no_options
                                 }
                               end

          new_variant = Variant.create!(variant_attributes)

          # Create inventory with proper variant association
          inventory_attributes = if base_variant
                                   {
                                     variant_id: new_variant.id,
                                     count_on_hand: base_variant.inventory.count_on_hand,
                                     count_pending_to_customer: base_variant.inventory.count_pending_to_customer
                                   }
                                 else
                                   {
                                     variant_id: new_variant.id,
                                     count_on_hand: 20,
                                     count_pending_to_customer: 0
                                   }
                                 end

          new_inventory = Inventory.create!(inventory_attributes)

          # Update variant with inventory association
          new_variant.update!(inventory_id: new_inventory.id)

          new_variant.reload # Ensure associations are properly loaded
          return new_variant
        end

      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error("Variant creation failed: #{e.message}")
        raise StandardError, "Variant creation failed for supplier #{supplier.id}, liquid_variant_id #{item[:liquidId]}: #{e.message}"
      end

      def build_order_item_attributes(item, variant, supplier, user)
        cart_item_id = item[:cartItemId]

        # Convert MongoDB ID to numeric
        item_identifier = LiquidCommerceIdConverter.to_numeric(cart_item_id)

        Rails.logger.info("[LIQUID_COMMERCE] Converting ID - #{JSON.generate({
                                                                               cart_id: cart_item_id,
                                                                               numeric_id: item_identifier
                                                                             })}")

        {
          identifier: item_identifier,
          item_id: item[:cartItemId],
          variant_id: variant.id,
          quantity: item[:quantity],
          price: item[:unitPrice].to_f / 100,
          tax_charge: (item[:tax] || 0).to_f / 100,
          bottle_deposits: (item[:bottleDeposits] || 0).to_f / 100,
          user: user
        }
      end
    end

    resource :checkout do
      params do
        optional :token, type: String
        requires :cartId, type: String, desc: 'Liquid Cart id'
        requires :hasAgeVerify, type: Boolean
        requires :hasSubstitutionPolicy, type: Boolean
        optional :scheduledDelivery, type: String
        requires :existingAccountId, type: Integer
        requires :storefrontId, type: Integer
        requires :shippingAddressId, type: Integer
        requires :billingAddressId, type: Integer
        requires :paymentProfileId, type: Integer
        requires :customer, type: Hash do
          requires :email, type: String
          requires :firstName, type: String
          requires :lastName, type: String
          requires :phone, type: String
          requires :birthDate, type: String
          optional :company, type: String
        end
        requires :isGift, type: Boolean
        optional :giftOptions, type: Hash do
          requires :message, type: String
          requires :recipient, type: Hash do
            requires :name, type: String
            requires :email, type: String
            optional :phone, type: String
          end
        end
        requires :marketingPreferences, type: Hash do
          requires :canEmail, type: Boolean
          requires :canSms, type: Boolean
        end
        requires :items, type: Array do
          requires :partNumber
          requires :quantity
        end
      end

      post do
        # Checkout Processing
        started_at = Time.zone.now

        # Fetch the storefront
        storefront = Storefront.find_by(id: params[:storefrontId])
        error!({ number: nil, errors: [message: 'Storefront not found.', code: 50] }, 400) unless storefront

        begin
          # Find existing user
          user = RegisteredAccount.find_by(id: params[:existingAccountId])&.user
          error!({ number: nil, errors: [message: 'User not found.', code: 51] }, 400) unless user

          # Update user birthdate if provided and empty
          if params[:hasAgeVerify] && params[:customer][:birthDate].present? && user.birth_date.blank?
            birthdate = Date.parse(params[:customer][:birthDate])
            user.update(birth_date: birthdate) if birthdate.present? && birthdate.age >= 21
          end
        rescue StandardError => e
          Rails.logger.error("User creation failed: #{e}. \n#{e.backtrace}")
          error!({ number: nil, errors: [message: 'Error creating user.', code: 51] }, 400)
        end

        # Fetch shipping address
        ship_address = Address.find_by(id: params[:shippingAddressId])
        unless ship_address
          error!({ number: nil, errors: [message: 'Shipping address not found.', code: 52] }, 400)
        end

        # Fetch billing address
        bill_address = Address.find_by(id: params[:billingAddressId])
        unless bill_address
          error!({ number: nil, errors: [message: 'Billing address not found.', code: 53] }, 400)
        end

        # Create order
        begin
          order = user.orders.new(
            storefront: storefront,
            ship_address: ship_address,
            bill_address: bill_address,
            email: params[:customer][:email],
            birthdate: params[:customer][:birthDate],
            delivery_notes: params[:deliveryNotes],
            button_referrer_token: params[:buttonReferrerToken],
            shoprunner_token: params[:shoprunnerToken],
            allow_substitution: params[:hasSubstitutionPolicy],
            storefront_cart_id: params[:cartId]
          )

          order.liquid = true

          # Create order_amount if amounts are present
          if params[:amounts].present?
            amount_attributes = LiquidcommerceAmountCalculator.calculate_core_amounts(params[:amounts], params[:amounts][:details])
            order.build_order_amount(amount_attributes)
          end

          # Create the initial order without validating amounts
          order.save(validate: false)

          liquidcommerce_identifiers = []

          # Build order_items
          order_items = params[:items].each_with_index.map do |item, index|
            retailer_id = item[:retailerId]
            retailer = params[:retailers].find { |r| r[:id] == retailer_id }
            raise StandardError, "Retailer not found for id: #{retailer_id}" unless retailer

            supplier_id = item[:selectedLegacySupplierId]
            supplier = Supplier.find_by(id: supplier_id)
            raise StandardError, "Supplier not found for id: #{supplier_id}" unless supplier

            # Validate that supplier has shipping methods
            unless supplier.shipping_methods.any?
              raise StandardError, "No shipping methods found for supplier: #{supplier_id}"
            end

            product = Product.find_by(id: item[:salsifyPid])
            raise StandardError, "Product not found for salsifyPid: #{item[:salsifyPid]}" unless product

            # Find or create variant
            variant = find_or_create_variant(
              item: item,
              supplier: supplier,
              product: product
            )

            # Build item options
            item_options = nil
            if item[:attributes]&.dig(:giftCard, :sender).present?
              item_options = GiftCardOptions.new(
                sender: item[:attributes][:giftCard][:sender],
                message: item[:attributes][:giftCard][:message],
                recipients: item[:attributes][:giftCard][:recipients],
                send_date: item[:attributes][:giftCard][:sendDate]
              )
            elsif item[:attributes]&.dig(:engraving, :hasEngraving)
              item_options = EngravingOptions.new(
                line1: item[:attributes][:engraving][:lines][0].presence,
                line2: item[:attributes][:engraving][:lines][1].presence,
                line3: item[:attributes][:engraving][:lines][2].presence,
                line4: item[:attributes][:engraving][:lines][3].presence
              )
            end

            item_attributes = build_order_item_attributes(item, variant, supplier, user)

            Rails.logger.info("[LIQUID_COMMERCE] Order item created - - #{JSON.generate({
                                                                                          cart_item_id: item[:cartItemId],
                                                                                          identifier: item_attributes[:identifier],
                                                                                          variant_id: item_attributes[:variant_id]
                                                                                        })}")

            item_attributes[:item_options] = item_options if item_options.present?

            # Collect identifier and cart_item_id in the array
            liquidcommerce_identifiers << {
              identifier: item_attributes[:identifier],
              cart_item_id: item[:cartItemId],
              supplier: supplier
            }

            item_attributes
          end

          order_params = {
            retailers: params[:retailers],
            liquidcommerce_identifiers: liquidcommerce_identifiers,
            order_items: order_items || [],
            shipping_address_id: params[:shippingAddressId],
            payment_profile_id: params[:paymentProfileId],
            customer: params[:customer],
            hasAgeVerify: params[:hasAgeVerify],
            hasSubstitutionPolicy: params[:hasSubstitutionPolicy],
            isGift: params[:isGift],
            giftOptions: params[:giftOptions],
            amounts: params[:amounts]
          }

          # Handle gift options - create GiftDetail first and then associate with order
          if params[:isGift] && params[:giftOptions].present?
            gift_detail = GiftDetail.new(
              user: user,
              message: params[:giftOptions][:message],
              recipient_name: params[:giftOptions][:recipient][:name],
              recipient_email: params[:giftOptions][:recipient][:email],
              recipient_phone: params[:giftOptions][:recipient][:phone]
            )

            if gift_detail.save
              order.gift_detail = gift_detail
              order.save!
            else
              Rails.logger.info("GIFT DETAIL ERRORS: #{gift_detail.errors.full_messages}")
              error!({ number: nil, errors: [message: 'Error creating gift details.', code: 54] }, 400)
            end
          end
        rescue StandardError => e
          Rails.logger.error("Error creating order: #{e}. \n #{e.backtrace}")
          error!({ number: nil, errors: [message: 'Error creating order.', code: 54] }, 400)
        end

        # Assign payment profile
        payment_profile = PaymentProfile.find_by(id: params[:paymentProfileId])
        unless payment_profile
          error!({ number: nil, errors: [message: 'Payment profile not found.', code: 56] }, 400)
        end

        if params[:couponId].present?
          test = Coupon.find_by(id: params[:couponId])
          order.coupon = test
        end

        order.payment_profile = payment_profile
        order.save!

        # Initialize OrderCreationServicesV2
        begin
          order_service = OrderCreationServicesV2.new(
            order,
            user,
            order_params,
            skip_scheduling_check: true,
            skip_in_stock_check: true
          )
          if order_service.build_order
            # Proceed with order finalization using FinalizeOrderServiceV2
            finalize_service = FinalizeOrderServiceV2.new(
              order,
              {
                legal_age_agreement: params[:hasAgeVerify],
                skip_legal_age_agreement: !params[:hasAgeVerify]
              }
            )

            order.finalize! unless order.finalizing?

            if finalize_service.process

              Rails.logger.info("Finalize order (took #{Time.zone.now - started_at})")

              status 200
              { 'number': order.number.to_s }
            else
              error!({ number: nil, errors: finalize_service.errors.full_messages }, 400)
            end
          else
            error!({ number: nil, errors: order_service.error.detail }, order_service.error.status)
          end
        rescue StandardError => e
          Rails.logger.error("Error processing order: #{e}. \n#{e.backtrace}")
          error!({ number: nil, errors: [message: 'Error processing order.', code: 55] }, 400)
        end
      end
    end
  end
end
