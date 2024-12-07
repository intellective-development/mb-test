class ConsumerAPIV2::CartEndpoint < BaseAPIV2
  helpers Shared::Helpers::ItemOptionsHelpers
  helpers Shared::Helpers::CartEndpointHelpers

  namespace :cart do # rubocop:disable Metrics/BlockLength
    desc 'Creates a new order associated with the user', ConsumerAPIV2::DOC_AUTH_HEADER
    params do
      optional :storefront_cart_id, type: String
      optional :coupon_code,        type: String
      optional :gtm_visitor_id,     type: String
      optional :gift_order,         type: Boolean
      optional :age_verified,       type: Boolean
      optional :membership_plan_id, type: Integer
      optional :return_cart_amount, type: Boolean, default: false
      optional :address, type: Hash do
        requires :address1,   type: String, desc: 'Address 1', allow_blank: false
        optional :address2,   type: String, desc: 'Address 2', default: ''
        optional :city,       type: String, desc: 'City'
        optional :state_name, type: String, desc: 'State'
        requires :zip_code,   type: String, desc: 'Zipcode', allow_blank: false
      end
    end

    post do
      error!('Storefront cart id is required for SFCC storefronts', 400) if @params[:storefront_cart_id].blank? && storefront.sfcc?

      cart_trait = nil
      trait_param_keys = %i[coupon_code gtm_visitor_id gift_order age_verified membership_plan_id]
      if trait_param_keys.any? { |key| @params.include?(key) }
        cart_trait = CartTrait.new(
          coupon_code: @params[:coupon_code],
          gtm_visitor_id: @params[:gtm_visitor_id],
          membership_plan_id: @params[:membership_plan_id]
        )
        cart_trait.gift_order = @params[:gift_order] if @params[:gift_order]
        cart_trait.age_verified = @params[:age_verified] if @params[:age_verified]
      end

      cart = Cart.create(
        user_id: @user.try(:id),
        doorkeeper_application: doorkeeper_application,
        storefront: storefront,
        storefront_cart_id: @params[:storefront_cart_id],
        cart_trait: cart_trait
      )

      cart.create_address(@params[:address].merge!(address_purpose: :shipping, name: 'Shipping Address')) if @params[:address]

      cart.cart_amount = Carts::CartAmountService.new(cart).call if params[:return_cart_amount]

      present cart, with: ConsumerAPIV2::Entities::Cart, address: user_address
    end

    route_param :id do
      before do
        @cart = Cart.includes(cart_items: [:variant]).find_by(id: params[:id])
        error!('Cart not found', 404) if @cart.nil?

        @cart.convert_to_standard_cart(user_address, params[:supplier_ids]) if @cart.has_attribute?('type') && !@cart.type.nil? && params[:supplier_ids]
        claim_cart if @user && @cart.user_id.nil?
        error!('Unauthorized', 403) if logged_in_and_cart_belongs_to_another_user
      end

      desc 'Retrieve cart, with full cart item objects.', ConsumerAPIV2::DOC_AUTH_HEADER
      params do
        requires :id, type: String, allow_blank: false
        optional :skip_bundle, type: Boolean
        optional :supplier_ids, type: Array, default: [], coerce_with: ->(arr) { arr.reject { |val| val.to_i.zero? } }
        optional :return_cart_amount, type: Boolean, default: false
      end
      get do
        @cart.remove_invalid_items!(params[:supplier_ids], use_in_stock_check?)

        cart_item = @cart.cart_items.active.last
        suggestions = if cart_item&.variant && !params[:skip_bundle]
                        bundle_service = BundleService.new(cart_item.variant.id, @cart.id, storefront.business, params, request.headers['Authorization'])
                        bundle_service.find_bundle_options
                      end

        @cart.cart_amount = Carts::CartAmountService.new(@cart).call if params[:return_cart_amount] && @cart.cart_amount.blank?

        present @cart, with: ConsumerAPIV2::Entities::Cart, bundle: bundle_service&.bundle, suggestions: suggestions, address: user_address
      end

      desc 'Update all cart items', ConsumerAPIV2::DOC_AUTH_HEADER
      params do
        optional :cart_share_id, type: String
        optional :supplier_ids, type: Array, default: [], coerce_with: ->(arr) { arr.reject { |val| val.to_i.zero? } }
        optional :coupon_code, type: String
        optional :gtm_visitor_id, type: String
        optional :decision_log_uuids, type: Hash
        optional :gift_order, type: Boolean
        optional :age_verified, type: Boolean
        optional :membership_plan_id, type: Integer
        optional :in_stock_validation, type: Boolean, default: false
        optional :return_cart_amount, type: Boolean, default: false
        optional :cart_items, type: Array, default: [] do
          requires :identifier, type: String, allow_blank: false
          optional :product_bundle_external_id, type: String
          optional :variant_id, type: String, allow_blank: false
          optional :customer_placement, type: String, values: -> { CartItem.customer_placements.keys + ['undefined'] }, coerce_with: ->(val) { val == 'undefined' ? 'standard' : val }
          given variant_id: ->(id) { !Variant.gift_card?(id) } do
            requires :quantity, type: Integer, default: 1
          end
          use :item_options_params
        end
      end

      after_validation { set_cart_items }
      format :json
      put do
        # Performs in_stock validation if it's requested by the client
        in_stock_validation(params[:cart_items]) if params[:in_stock_validation]

        # These loops are not very efficient. Would be better if we could perform all creates
        # and updates at once, and perhaps validate all variant ids immediately beforehand?
        @cart.cart_items.each(&:inactivate!) if params[:cart_share_id].present?
        @cart_items.each do |item_params|
          cart_item = @cart.cart_items.find_by(identifier: item_params[:identifier])

          cart_item_process = Carts::ProcessCartItem.call(@cart, cart_item, item_params, storefront)
          error!(cart_item_process.error_message, 400) if cart_item_process.error_message.present?
        end

        # update cart trait items such as gift_order, age_verified, coupon_code and gtm_visitor_id
        update_cart_trait

        @cart.cart_amount = Carts::CartAmountService.new(@cart.reload).call if params[:return_cart_amount]

        present @cart, with: ConsumerAPIV2::Entities::Cart, address: user_address
      end

      desc 'Deactivate (hide) all cart items.', ConsumerAPIV2::DOC_AUTH_HEADER
      delete do
        @cart.cart_items.each(&:inactivate!)

        present @cart, with: ConsumerAPIV2::Entities::Cart, address: user_address
      end

      namespace :gift_card do
        desc 'Add new gift card to the cart.', ConsumerAPIV2::DOC_AUTH_HEADER
        params do
          requires :code, type: String, desc: 'Gift card code', allow_blank: false
          optional :return_cart_amount, type: Boolean, default: false
        end
        post do
          gift_card_code = params[:code]&.downcase

          gift_card = CouponDecreasingBalance.active.find_by(code: gift_card_code&.downcase, storefront: storefront)

          error!({ name: 'GiftCardError', messages: [I18n.t('coupons.errors.generic', promo_code: gift_card_code)] }, 422) if gift_card.nil?

          eligible, reason = GiftCard::GiftCardEligibilityService.new(cart: @cart).eligible?(gift_card)

          error!({ name: 'GiftCardError', messages: [reason] }, 422) unless eligible

          @cart.gift_cards.push(gift_card)
          @cart.cart_amount = Carts::CartAmountService.new(@cart).call if params[:return_cart_amount]
          @cart.save!

          present @cart, with: ConsumerAPIV2::Entities::Cart
        end
      end

      namespace :promo_code do
        desc 'Validate and add or remove a new promo code to the cart', ConsumerAPIV2::DOC_AUTH_HEADER
        params do
          requires :code, type: String, desc: 'Promo code', allow_blank: false
          optional :return_cart_amount, type: Boolean, default: false
        end
        post do
          coupon = Coupon.find_by(code: @params[:code].downcase, storefront: storefront)

          error!({ name: 'PromoCodeError', messages: ["The code '#{@params[:code]}' is invalid"] }, 422) if coupon.blank? || coupon.inactive?

          eligibility_service = PromoCode::PromoCodeEligibilityService.new(@cart, coupon)

          eligibility_service.eligible?
          if (error_messages = eligibility_service.errors).present?
            error!({ name: 'PromoCodeError', messages: error_messages }, 422)
          else
            @cart.update(promo_code: coupon)
            @cart.cart_amount = Carts::CartAmountService.new(@cart).call if params[:return_cart_amount]

            present @cart, with: ConsumerAPIV2::Entities::Cart
          end
        end

        params do
          optional :return_cart_amount, type: Boolean, default: false
        end
        delete do
          @cart.update(promo_code: nil)
          @cart.cart_amount = Carts::CartAmountService.new(@cart).call if params[:return_cart_amount]

          present :amounts, @cart.cart_amount, with: ConsumerAPIV2::Entities::CartAmount
        end
      end

      namespace :cart_item do
        route_param :identifier do
          before do
            @variant_id = @params[:variant_id]
            @quantity = @params[:quantity].to_i
            @cart_item = @cart.cart_items.find_by(identifier: @params[:identifier])
          end

          desc 'Update individual cart item', ConsumerAPIV2::DOC_AUTH_HEADER
          params do
            requires :id, type: String, allow_blank: false, desc: 'Cart ID'
            requires :identifier, type: String, allow_blank: false
            optional :variant_id, type: String, allow_blank: false
            optional :supplier_ids, type: Array, desc: 'Supplier ID(s)', coerce_with: ->(val) { val }
            optional :skip_bundle, type: Boolean
            optional :customer_placement,         type: String, values: -> { CartItem.customer_placements.keys }
            optional :product_bundle_external_id, type: String
            optional :in_stock_validation, type: Boolean, default: false
            optional :tracking, type: Hash do
              optional :search_id, type: Integer, desc: 'Elastic Search query tracking id'
              optional :options, type: Hash, default: nil
            end
            given variant_id: ->(id) { !Variant.gift_card?(id) } do
              requires :quantity, type: Integer, default: 1
            end
            use :item_options_params
          end
          put do
            item_params = {
              identifier: params[:identifier],
              variant_id: @variant_id || params[:identifier],
              quantity: @quantity,
              item_options: @params[:options],
              customer_placement: params[:customer_placement] || 0,
              product_bundle: product_bundle(params[:product_bundle_external_id])
            }

            in_stock_item_validation(item_params) if params[:in_stock_validation] && @cart_item&.standard?

            cart_item_process = Carts::ProcessCartItem.call(@cart, @cart_item, item_params, storefront)
            error!(cart_item_process.error_message, 400) if cart_item_process.error_message.present?

            @cart_item = cart_item_process.cart_item

            unless params[:skip_bundle]
              bundle_service = BundleService.new(@variant_id, params[:id], storefront.business, params, request.headers['Authorization'])
              suggestions = bundle_service.find_bundle_options
            end

            present @cart_item, with: ConsumerAPIV2::Entities::CartItem, suggestions: suggestions, bundle: bundle_service&.bundle, address: user_address
          end
        end
      end
    end

    resource :add do
      before do
        error!('Storefront cart id is required for SFCC storefronts', 400) if @params[:storefront_cart_id].blank? && storefront.sfcc?

        @cart = Cart.create(
          user_id: @user.try(:id), doorkeeper_application: doorkeeper_application,
          storefront: storefront, storefront_cart_id: @params[:storefront_cart_id]
        )
      end

      desc 'Update all cart items', ConsumerAPIV2::DOC_AUTH_HEADER
      params do
        requires :skus, type: String, default: ''
      end
      post do
        skus = params[:skus].split(',')
        skus.each do |item_sku|
          variant = Variant.find_by(sku: item_sku)
          error!("Product #{item_sku} is not valid.") if variant.nil?
          error!("Product #{variant.product_name} is not available.") if use_in_stock_check? && variant.inactive?

          cart_item = @cart.cart_items.find_by(identifier: variant.id)
          item_params = {
            identifier: variant.id, variant_id: variant.id, quantity: quantity || 1,
            customer_placement: params[:customer_placement] || 0, product_bundle: product_bundle(params[:product_bundle_external_id])
          }

          cart_item_process = Carts::ProcessCartItem.call(@cart, cart_item, item_params, storefront)
          error!(cart_item_process.error_message, 400) if cart_item_process.error_message.present?
        end

        present @cart, with: ConsumerAPIV2::Entities::Cart, address: user_address
      end
    end

    resource :shares do
      route_param :cart_share_id do
        before do
          @cart_share = CartShare.includes(:coupon)
                                 .find_by(id: params[:cart_share_id])

          error!('CartShare not found', 404) if @cart_share.nil?
        end

        desc 'Retrieve cart_share as is.', ConsumerAPIV2::DOC_AUTH_HEADER
        params do
          requires :cart_share_id, type: String, desc: 'Cart Share ID.'
        end
        get do
          present @cart_share, with: ConsumerAPIV2::Entities::CartShare, business: storefront.business, address: user_address
        end
      end
    end
  end
end
