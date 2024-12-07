class SupplierAPIV3::ShipmentsEndpoint < BaseAPIV3
  helpers do
    params :pagination do
      optional :page, type: Integer, default: 1
      optional :per_page, type: Integer, default: 20
    end

    params :sorting do
      optional :sort_column, type: String, values: %w[created_at status], default: 'created_at'
      optional :sort_direction, type: Symbol, values: %i[asc desc], default: :desc
    end

    params :filtering do
      optional :filters, type: Hash, default: {} do
        optional :date_range, type: Hash do
          optional :start, type: String
          optional :end, type: String
        end
        optional :delivery_method_types, type: Array
        optional :attributes, type: Array, default: []
        optional :keywords, type: Array, default: []
      end
    end

    def current_supplier
      return @current_supplier = Supplier.find(params[:supplier_id]) if ENV['ENV_NAME'] != 'master' && params[:supplier_id].present?

      super
    end

    def keywords
      query = {}
      params.dig(:filters, :keywords)&.each do |keyword|
        case keyword[:key]
        when 'First Name'
          query[:registered_accounts] ||= {}
          query[:registered_accounts][:first_name] = keyword[:value]
        when 'Last Name'
          query[:registered_accounts] ||= {}
          query[:registered_accounts][:last_name] = keyword[:value]
        when 'Order Number'
          query[:orders] ||= {}
          query[:orders][:number] = keyword[:value]
        when 'Gift Recipient'
          query[:gift_details] ||= {}
          query[:gift_details][:recipient_name] = keyword[:value]
        when 'Custom Tag'
          query[:custom_tags] ||= {}
          query[:custom_tags][:name] = keyword[:value]
        when 'Storefront Name'
          query[:orders] ||= {}
          query[:orders][:storefronts] ||= {}
          query[:orders][:storefronts][:name] = keyword[:value]
        end
      end
      query
    end

    def attributes
      params.dig(:filters, :attributes)
    end

    def states(states)
      return states unless attributes

      override_states = attributes.select { |value| ShipmentStateMachine::SUPPLIER_VISIBLE_STATES.include?(value) }
      override_states.any? ? override_states : states
    end

    def shipping_states
      return %w[paid scheduled] if attributes&.include?('unconfirmed')
      return %w[confirmed ready_to_ship] if attributes&.include?('confirmed')

      ShipmentStateMachine::SHIPPING_STATES
    end

    def date_range
      date_start = params.dig(:filters, :date_range, :start)
      date_end = params.dig(:filters, :date_range, :end)
      date_start..date_end if date_start.present? && date_end.present?
    end

    def vip?
      attributes&.include?('vip')
    end

    def gift?
      attributes&.include?('gift')
    end

    def engraving?
      attributes&.include?('engraving')
    end

    def shipping_types
      params.dig(:filters, :delivery_method_types)
    end

    def shipments_query(order_states = Order::SUPPLIER_VISIBLE_STATES)
      keys = params.dig(:filters, :keywords)

      query = Shipment.joins(:order, :shipping_method)

      query.joins!(:user) if vip?
      query.joins!(order_items: :item_options) if engraving?

      query.joins!(user: :registered_account) if key?('First Name', 'Last Name')
      query.joins!(order: :gift_detail) if key?('Gift Recipient')
      if key?('Product Name')
        query.joins!(order_items: { variant: { product: :product_size_grouping } })
        query = query.left_joins(order_items: { variant: { product: :product_trait } })
      end
      query.joins!(custom_tag_shipments: :custom_tag) if key?('Custom Tag')
      query.joins!(order: :storefront) if key?('Storefront Name')

      query.where(supplier_id: current_supplier_ids).where(orders: { state: order_states })
    end

    def key?(*values)
      values.flatten!
      params.dig(:filters, :keywords).to_a.any? { |k| values.include?(k[:key]) }
    end

    def filter_query(shipments)
      query = shipments.clone
      query.where!(users: { vip: true }) if vip?
      query.where!(orders: { created_at: date_range }) if date_range
      query.where!(shipping_methods: { shipping_type: shipping_types }) if shipping_types.present?

      query = query.where.not(orders: { gift_detail_id: nil }) if gift?
      query = query.where.not(item_options: { line1: nil }) if engraving?

      if params[:sort_column].present?
        case params[:sort_column]
        when 'status'
          query.order!("shipments.state #{params[:sort_direction]}")
        else
          query.order!(
            Arel.sql("greatest(shipments.created_at, orders.completed_at) #{params[:sort_direction]}")
          )
        end
      end

      if key?('Product Name')
        value = params.dig(:filters, :keywords)&.find { |k| k[:key] == 'Product Name' }&.dig(:value)
        query = query.merge(
          Shipment.where(product_traits: { title: value })
                  .or(Shipment.where(product_groupings: { name: value }))
        )
      end

      query
        .where(keywords)
        .page(params[:page])
        .per(params[:per_page])
    end

    def response(shipments)
      header 'X-Total', shipments.total_count.to_s
      header 'X-Total-Pages', shipments.total_pages.to_s

      present shipments, with: SupplierAPIV3::Entities::ShipmentListItem
    end
  end

  namespace :orders do
    desc 'Retrieve a list of orders.'
    params do
      use :filtering
      use :pagination
      use :sorting
    end
    get do
      shipment_states = states(ShipmentStateMachine::SUPPLIER_VISIBLE_STATES)

      response(filter_query(shipments_query.where!(state: shipment_states)))
    end

    desc 'Retrieve a list of completed orders.'
    params do
      use :filtering
      use :pagination
      use :sorting
    end
    get :completed do
      shipment_states = states(ShipmentStateMachine::COMPLETED_STATES)

      states_shipment_query =
        if shipping_types.present?
          Shipment.where(shipments: { state: shipment_states }, shipping_methods: { shipping_type: shipping_types })
        else
          Shipment.where(shipments: { state: shipment_states }, shipping_methods: { shipping_type: %w[on_demand pickup] })
                  .or(Shipment.where(shipments: { state: 'en_route' }, shipping_methods: { shipping_type: :shipped }))
        end

      response(filter_query(shipments_query.merge(states_shipment_query)))
    end

    desc 'Retrieve a list of todays orders and unconfirmed orders from other days.'
    params do
      use :filtering
      use :pagination
      use :sorting
    end
    get :today do
      unconfirmed_states = states(ShipmentStateMachine::UNCONFIRMED_STATES)
      today_states = states(ShipmentStateMachine::SUPPLIER_TODAY_VISIBLE_STATES)
      today_shipped_states = states(ShipmentStateMachine::SUPPLIER_TODAY_SHIPPED_VISIBLE_STATES)

      schedule_start = Time.zone.now.beginning_of_day - Shipment::SCHEDULING_BUFFER.hours
      schedule_end = Time.zone.now.end_of_day + Shipment::SCHEDULING_BUFFER.hours
      today_start = Time.zone.now.beginning_of_day - 3.hours
      today_end = Time.zone.now.end_of_day + 3.hours

      states_shipment_query =
        if shipping_types.present?
          Shipment.where(shipping_methods: { shipping_type: shipping_types })
                  .where(shipments: { state: unconfirmed_states.dup << 'exception' })
                  .or(Shipment.where(shipments: { state: %w[scheduled en_route confirmed], scheduled_for: schedule_start..schedule_end }))
                  .or(Shipment.where(shipments: { state: today_states },
                                     orders: { completed_at: today_start..today_end }))
        else
          Shipment.where(shipments: { state: unconfirmed_states.dup << 'exception' })
                  .or(Shipment.where(shipments: { state: %w[scheduled en_route confirmed], scheduled_for: schedule_start..schedule_end },
                                     shipping_methods: { shipping_type: %w[on_demand pickup] }))
                  .or(Shipment.where(shipments: { state: %w[scheduled confirmed], scheduled_for: schedule_start..schedule_end },
                                     shipping_methods: { shipping_type: :shipped }))
                  .or(Shipment.where(shipments: { state: today_states },
                                     orders: { completed_at: today_start..today_end },
                                     shipping_methods: { shipping_type: %w[on_demand pickup] }))
                  .or(Shipment.where(shipments: { state: today_shipped_states },
                                     orders: { completed_at: today_start..today_end },
                                     shipping_methods: { shipping_type: :shipped }))
        end

      response(filter_query(shipments_query.merge(states_shipment_query)))
    end

    desc 'Retrieve a list of scheduled orders.'
    params do
      use :filtering
      use :pagination
      use :sorting
    end
    get :scheduled do
      query = shipments_query

      query.where!(state: 'scheduled')
           .where!(Shipment.arel_table[:scheduled_for].gt(Time.zone.now + Shipment::SCHEDULING_BUFFER.hours))
           .order!(scheduled_for: :desc)

      response(filter_query(query))
    end

    desc 'Retrieve a list of shipping orders.'
    params do
      use :filtering
      use :pagination
      use :sorting
    end
    get :shipping do
      query = shipments_query(Order::TRACKABLE_STATES).left_joins(:tracking_detail, :packages)

      query.where!(shipments: { state: shipping_states },
                   shipping_methods: { shipping_type: 'shipped' },
                   shipment_tracking_details: { id: nil },
                   packages: { id: nil })

      response(filter_query(query))
    end

    desc 'Retrieve a list of pre-sale orders.'
    params do
      use :filtering
      use :pagination
      use :sorting
    end
    get :pre_sale do
      response(filter_query(shipments_query.where(state: 'pre_sale')))
    end

    desc 'Retrieve a list of back-order orders.'
    params do
      use :filtering
      use :pagination
      use :sorting
    end
    get :back_order do
      response(filter_query(shipments_query.where(state: 'back_order')))
    end

    desc 'Retrieve a list of exception orders.'
    params do
      use :filtering
      use :pagination
      use :sorting
    end
    get :exception do
      response(filter_query(shipments_query.where(state: 'exception')))
    end
  end
end
