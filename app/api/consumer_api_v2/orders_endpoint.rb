class ConsumerAPIV2::OrdersEndpoint < BaseAPIV2
  helpers Shared::Helpers::OrderEndpointHelpers
  helpers Shared::Helpers::ItemOptionsHelpers
  helpers Shared::Helpers::GiftParamHelpers
  helpers Shared::Helpers::OrderParamHelpers
  helpers Shared::Helpers::FraudHelpers
  helpers Shared::Helpers::AuthHelpers
  helpers Shared::Helpers::AddressHelpers
  helpers Shared::Helpers::AddressParamHelpers

  include Shared::Helpers::PaymentPartners::Authenticatable

  # Routes
  namespace :order do
    before do
      authenticate!
      validate_device_udid!
    end

    desc 'Creates a new order associated with the user', ConsumerAPIV2::DOC_AUTH_HEADER
    params do
      use :order_create
    end

    before do
      set_cart_id
      set_ip_address_in_params
      set_storefront_in_params
    end

    post do
      params[:tip] = nil unless params.nil? || params.key?(:tip)
      skip_tax_calculation = params.key?(:skip_tax_calculation) ? params[:skip_tax_calculation] : false

      create_or_update_order!(skip_tax_calculation: skip_tax_calculation)

      if @order.save
        set_default_tip if should_set_default_tip? || !allows_tip?

        present @order, with: ConsumerAPIV2::Entities::Order, expose_shipments: true
      else
        error!('Order is invalid', 400)
      end
    end

    route_param :number do
      before do
        # TODO: Should we be eager loading order_items, shipments, suppliers, variants, tax rates etc. here? (YES!)
        @order = @user.orders.find_by(number: params[:number])
        error!('Invalid Order Number', 400) if @order.nil?
        Sentry.set_extras(order: { number: @order.number, id: @order.id })

        set_ip_address_in_params
        set_storefront_in_params
      end

      desc 'Update an order associated with a user', ConsumerAPIV2::DOC_AUTH_HEADER
      params do
        use :order_update
      end
      put do
        unless @order.in_progress?
          Rails.logger.info("Order cannot be updated. Order id: #{@order.id}, state: #{@order.state}.")
          error!('Order is not in a state to be edited', 400)
        end
        previous_allows_tip = allows_tip?

        create_or_update_order!

        # Save and return
        if @order.save
          # we want to remove the tip if no shipping_methods allows tips and we want to add the default tip back
          # if it used not have not no shipping_methods allowing tips and now it allows
          set_default_tip if should_set_default_tip? || !allows_tip? || (!previous_allows_tip && allows_tip?)

          present @order, with: ConsumerAPIV2::Entities::Order, expose_shipments: true
        else
          error!('Order is invalid', 400)
        end
      end

      desc 'Returns order info', headers: ConsumerAPIV2::DOC_AUTH_HEADER
      params do
        requires :number, type: String
      end
      get do
        present :order, @order, with: ConsumerAPIV2::Entities::Order, expose_shipments: true
      end

      namespace :actions do
        desc 'Finalizes and charges an order.', ConsumerAPIV2::DOC_AUTH_HEADER
        params do
          use :order_finalize
          optional :device_data, type: String, desc: 'Device fingerprint data used for anti-fraud risk scoring'
        end

        post :finalize do
          # calculate_order_taxes
          status, order_state = finalize_order_helper!
          status status
          present @order,
                  with: ConsumerAPIV2::Entities::Order,
                  override_order_state: order_state,
                  expose_shipments: true
        rescue UnauthorizedError
          error!('Unauthorized.', 401)
        rescue FinalizeOrderError
          error!('Order is invalid', 400)
        rescue CreateOrUpdateOrderError => e
          error!(JSON.parse(e.message), 400)
        rescue RedisMutex::LockError
          error!('Could not Finalize this Order at this Moment', 422)
        rescue StandardError => e
          error!(JSON.parse(e.message), 400)
        end
      end

      namespace :csv do
        route_param :item do
          before do
            @order = @user.orders.find_by(number: params[:number])
            error!('Invalid Order Number', 400) if @order.nil?
            @order_item = @order.order_items.find { |oi| oi.item_options&.id == params[:item].to_i }
            error!('Invalid Item Option Number', 400) if @order_item.nil?
          end
          desc 'Get CSV'
          get do
            content_type 'text/csv'
            header['Content-Disposition'] = "attachment; filename=order_#{params[:number]}.csv"
            env['api.format'] = :binary
            @order_item.item_options&.to_csv
          end
        end
      end

      namespace :void do
        params do
          requires :storefront_uuid, type: String, allow_blank: false
        end

        before do
          validate_storefront_uuid!
          error!('Unauthorized.', 401) unless valid_payment_partner_request?
        end

        desc 'Voids order'
        put do
          @order.cancel!

          present :order, @order, with: ConsumerAPIV2::Entities::Order
        end
      end

      namespace :metadata do
        params do
          requires :metadata, type: Hash
        end

        put do
          @order.metadata = @params[:metadata] unless @params[:metadata].nil?

          if @order.save
            present :success, true
          else
            Rails.logger.error("Could not save order metadata. Order id: #{@order.id}, errors: #{@order.errors.to_s if @order.errors.present?}")
            error!({ status: 'error', message: 'Order cannot be updated' }, 400)
          end
        end
      end
    end
  end

  namespace :orders do
    before do
      authenticate!
      validate_device_udid!
    end

    desc 'Retrives a list of the customers orders', ConsumerAPIV2::DOC_AUTH_HEADER
    params do
      optional :page, type: Integer, desc: '', minimum_value: 1, default: 1
      optional :per_page, type: Integer, desc: '', maximum_value: 10, default: 8
      optional :include_pagination, type: Boolean, desc: '', default: false
    end
    get do
      count = @user.orders.finished.order(completed_at: :desc).count
      @orders = @user.orders
                     .includes(:order_amount, :coupon, :payment_profile, :ship_address, order_items: [variant: %i[product product_size_grouping]], shipments: [:shipping_method, { supplier: [:address] }])
                     .finished
                     .order(completed_at: :desc)
                     .page(params[:page])
                     .per(params[:per_page])

      status 200
      if params[:include_pagination]
        present :orders, @orders, with: ConsumerAPIV2::Entities::Order, expose_shipments: true
        present :number_of_pages, (count / params[:per_page].to_f).ceil
        present :page, params[:page].to_i
        present :per_page, params[:per_page].to_i
      else
        present @orders, with: ConsumerAPIV2::Entities::Order, expose_shipments: true
      end
    end
  end

  namespace :order do
    route_param :number do
      before { set_order }

      namespace :storefront_checkout do
        desc "Returns information about the order's suppliers, cart and address"

        params do
          requires :storefront_uuid, type: String, allow_blank: false
        end

        get do
          validate_storefront_uuid!

          present :doorkeeper_token, @user.access_token if @user&.account&.guest? || @user&.guest?
          present :order, @order, with: ConsumerAPIV2::Entities::Order, expose_shipments: true, expose_cart: true
          present :suppliers, @order.suppliers.uniq,
                  with: ConsumerAPIV2::Entities::Supplier,
                  shipping_methods: @order.shipping_methods,
                  filter_best_shipping_method: false
          present :shipping_address, @order.ship_address, with: ConsumerAPIV2::Entities::Address
        end
      end

      namespace :exchange_user do
        route_param :storefront_uuid do
          post do
            validate_storefront_uuid!

            error!('User not found with given token.', 404) if @user.blank?

            if @order&.user_id != @user.id
              saved = @order.in_progress? && @order.user.guest_by_email? && @order.ship_address.update(addressable: @user) && @order.update(user: @user)
              saved = @order.cart.update(user: @user) if saved && @order.cart.present?

              error!('Order could not be exchanged.', 400) unless saved
            end

            present :success, true
          end
        end
      end

      namespace :storefront_config do
        desc "Order's Storefront information"

        get do
          error!('Order not found.', 400) unless @order

          present @order.storefront, with: ConsumerAPIV2::Entities::Storefront
        end
      end

      namespace :calculate_taxes do
        desc 'Calculate order taxes'

        post do
          calculate_order_taxes if @order.in_progress?
          present @order, with: ConsumerAPIV2::Entities::Amounts
        end
      end

      namespace :membership_plan do
        desc 'Add membership plan to the order'
        params do
          requires :membership_plan_id, type: Integer
        end
        post do
          result = Order::AddMembershipPlan.new(order: @order, membership_plan_id: params[:membership_plan_id]).call

          error!('Membership plan could not be add to the order.', 400) unless result.success?

          present :order, result.order, with: ConsumerAPIV2::Entities::Order
        end

        desc 'Remove membership plan from the order'
        delete do
          result = Order::RemoveMembershipPlan.new(order: @order, user: @user).call

          error!(result.error || 'Membership plan could not be removed from the order.', 400) unless result.success?

          present :order, result.order, with: ConsumerAPIV2::Entities::Order
        end
      end

      namespace :change_address do
        desc 'Returns the order item differences with a new address'
        params do
          requires :latitude, type: Float
          requires :longitude, type: Float
          requires :state_name, type: String
        end
        get do
          address = Address.new(latitude: params[:latitude], longitude: params[:longitude], state_name: params[:state_name])

          order_item_changes = ::Orders::ChangesOnAddressUpdateService.new(@order, address, storefront).call

          present order_item_changes
        end

        desc 'Changes the order address with the new items'
        params do
          use :create_address
          requires :order_items, type: Array do
            requires :ordem_item_id, type: Integer
            optional :new_product, type: Hash
            optional :error_message, type: String
          end
        end
        put do
          error!('Order not found.', 400) unless @order

          validate_address_phone_requirement

          address_params = address_params(params).merge!(state_name: params[:state])
          address = AddressCreationService.new(@user, doorkeeper_application).create(address_params)
          error!('Unable to save address', 400) unless address

          handle_opt_in

          ::Orders::ChangeAddressService.call(@order, @user, address, params[:order_items])

          @order.reload

          present :order, @order, with: ConsumerAPIV2::Entities::Order, expose_shipments: true, expose_cart: true
          present :suppliers, @order.suppliers.uniq,
                  with: ConsumerAPIV2::Entities::Supplier,
                  shipping_methods: @order.shipping_methods,
                  filter_best_shipping_method: false
          present :shipping_address, @order.ship_address, with: ConsumerAPIV2::Entities::Address

        rescue StandardError => e
          error!(e.message, 400)
        end
      end
    end

    namespace :storefront_claim do
      desc 'Creates order and returns redirection URL', ConsumerAPIV2::DOC_AUTH_HEADER

      params do
        use :order_create
        optional :number, type: String, allow_blank: false
        optional :storefront_uuid, type: String, allow_blank: false
        all_or_none_of :number, :storefront_uuid
      end

      before do
        set_ip_address_in_params
        set_storefront_in_params
      end

      after_validation do
        set_cart
        error!('Cart not found.', 400) unless @cart

        new_user = create_guest_user unless @user && @cart.user
        @cart.update!(user: new_user) unless @cart.user
        @user ||= new_user
      end

      post do
        if params[:number].present? && params[:storefront_uuid].present?
          @order = Order.pending.find_by(number: params[:number], storefront_uuid: params[:storefront_uuid])

          # We only accept orders with the following states: [:pending]
          error!('A order with a valid state was not found.', 400) if @order.nil?

          UpdateShipmentsService.new(@order, [], {}).cleanup_order_items
          @order.cart_id = params[:cart_id]
        end

        params[:tip] = nil unless tip_present?
        params[:storefront_cart_id] = @cart.storefront_cart_id
        @cart_id = params[:cart_id]
        should_recalculate = storefront.non_endemic?
        create_or_update_order!(skip_in_stock_check: @cart.skip_in_stock_check, skip_tax_calculation: !should_recalculate)
        set_default_tip if should_set_default_tip? || !allows_tip?

        present :url, build_redirection_endpoint
      end
    end
  end
end
