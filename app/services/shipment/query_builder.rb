class Shipment::QueryBuilder
  attr_reader :params, :query, :current_supplier_ids, :filters, :query_type, :current_supplier

  SEARCHABLE_FIELDS = [{ first_name: :word_start }, { last_name: :word_start }, :email, { number: :word_middle }, { gift_recipient: :word_start }, { street_address: :text_middle }, { company_name: :word_start }, { product_name: :text_middle }, { custom_tag: :text_middle }, { storefront_name: :word_start }].freeze
  INCLUDES = [:gift_detail, :comments, :address, :pickup_detail, :shipping_method, :shipment_amount, :supplier, :metadata, { order: [:payment_profile, { user: [:account] }], order_items: [variant: [:product, { product_size_grouping: [:hierarchy_type] }]] }].freeze
  TYPE_BASE_QUERY_MAP = {
    today: 'today_shipments_base_query',
    scheduled: 'scheduled_shipments_base_query',
    pre_sale: 'pre_sale_shipments_base_query',
    back_order: 'back_order_shipments_base_query',
    all: 'all_shipments_base_query',
    completed: 'completed_shipments_base_query',
    shipping: 'shipping_shipments_base_query',
    exception: 'exception_shipments_base_query'
  }.freeze

  def initialize(params, current_supplier_ids, type = :all)
    @current_supplier_ids = current_supplier_ids
    @filters = params[:filters]
    @filters[:attributes] = [] if @filters[:attributes].blank?
    @params = params
    @query_type = type
    @query = build_query
  end

  private

  def build_query
    query =  send(TYPE_BASE_QUERY_MAP[query_type])

    if filters[:date_range].present?
      query[:where][:completed_at_int] = {}
      query[:where][:completed_at_int][:gte] = Time.parse(filters[:date_range][:start]).to_i if filters[:date_range][:start].present?
      query[:where][:completed_at_int][:lte] = Time.parse(filters[:date_range][:end]).to_i   if filters[:date_range][:end].present?
    end

    query[:where][:shipping_type] = filters[:delivery_method_types] if filters[:delivery_method_types].present?

    override_states = filters[:attributes].select { |value| ShipmentStateMachine::SUPPLIER_VISIBLE_STATES.include?(value) }
    query[:where][:state] = override_states if override_states.any?
    query[:where][:vip]  = true if filters[:attributes].include?('vip')
    query[:where][:gift] = true if filters[:attributes].include?('gift')
    query
  end

  def base_query
    {
      fields: SEARCHABLE_FIELDS,
      includes: INCLUDES,
      order: { completed_at: :desc },
      operator: 'or',
      page: params[:page] || 1,
      per_page: params[:per_page] || 10,
      routing: @current_supplier_ids
    }
  end

  def all_shipments_base_query
    {
      where: {
        supplier_id: current_supplier_ids,
        state: ShipmentStateMachine::SUPPLIER_VISIBLE_STATES,
        order_state: Order::SUPPLIER_VISIBLE_STATES
      }
    }.merge(base_query)
  end

  # NOTE: All times are kept in server time ('America/New_York'), because the Shipment ElasticSearch
  # index doesn't use supplier's timezone for date fields. In order to make sure we catch all "Today" based
  # queries we check the 27 hour window between 00:00 ET and 23:59 PT

  def today_shipments_base_query
    {
      where: {
        supplier_id: current_supplier_ids,
        order_state: Order::SUPPLIER_VISIBLE_STATES,
        _or: [
          {
            state: ShipmentStateMachine::UNCONFIRMED_STATES
          },
          { # if shipment is scheduled_for and within buffer, include it unless terminal
            state: %w[scheduled en_route confirmed],
            scheduled_for: {
              gte: Time.zone.now.beginning_of_day - Shipment::SCHEDULING_BUFFER.hours,
              lte: Time.zone.now.end_of_day + Shipment::SCHEDULING_BUFFER.hours
            },
            shipping_type: %w[on_demand pickup]
          },
          {
            state: %w[scheduled confirmed],
            scheduled_for: {
              gte: Time.zone.now.beginning_of_day - Shipment::SCHEDULING_BUFFER.hours,
              lte: Time.zone.now.end_of_day + Shipment::SCHEDULING_BUFFER.hours
            },
            shipping_type: 'shipped'
          },
          {
            state: 'exception'
          },
          {
            state: ShipmentStateMachine::SUPPLIER_TODAY_VISIBLE_STATES,
            completed_at: {
              gte: Time.zone.now.beginning_of_day - 3.hours, # FIXME: shim to make sure we get West coast orders for today too
              lte: Time.zone.now.end_of_day + 3.hours # FIXME: shim to make sure we don't miss orders for 00-03 hours
            },
            shipping_type: %w[on_demand pickup]
          },
          {
            state: ShipmentStateMachine::SUPPLIER_TODAY_SHIPPED_VISIBLE_STATES,
            completed_at: {
              gte: Time.zone.now.beginning_of_day - 3.hours, # FIXME: shim to make sure we get West coast orders for today too
              lte: Time.zone.now.end_of_day + 3.hours # FIXME: shim to make sure we don't miss orders for 00-03 hours
            },
            shipping_type: 'shipped'
          }
        ]
      }
    }.merge(base_query)
  end

  def completed_shipments_base_query
    {
      where: {
        _or: [
          {
            supplier_id: current_supplier_ids,
            state: ShipmentStateMachine::COMPLETED_STATES,
            shipping_type: %w[on_demand pickup],
            order_state: Order::SUPPLIER_VISIBLE_STATES
          },
          {
            supplier_id: current_supplier_ids,
            state: 'en_route',
            shipping_type: 'shipped',
            order_state: Order::SUPPLIER_VISIBLE_STATES
          }
        ]
      }
    }.merge(base_query)
  end

  def scheduled_shipments_base_query
    {
      where: {
        supplier_id: current_supplier_ids,
        state: 'scheduled',
        order_state: Order::SUPPLIER_VISIBLE_STATES,
        scheduled_for: {
          gt: Time.zone.now + Shipment::SCHEDULING_BUFFER.hours
        }
      },
      order: {
        scheduled_for: :desc
      }
    }.merge(base_query)
  end

  def shipping_shipments_base_query
    {
      where: {
        supplier_id: current_supplier_ids,
        state: ShipmentStateMachine::SHIPPING_STATES,
        order_state: Order::TRACKABLE_STATES,
        shipping_type: 'shipped'
      }
    }.merge(base_query)
  end

  def pre_sale_shipments_base_query
    {
      where: {
        supplier_id: current_supplier_ids,
        state: :pre_sale,
        order_state: Order::SUPPLIER_VISIBLE_STATES
      }
    }.merge(base_query)
  end

  def back_order_shipments_base_query
    {
      where: {
        supplier_id: current_supplier_ids,
        state: :back_order,
        order_state: Order::SUPPLIER_VISIBLE_STATES
      }
    }.merge(base_query)
  end

  def exception_shipments_base_query
    {
      where: {
        supplier_id: current_supplier_ids,
        state: :exception,
        order_state: Order::SUPPLIER_VISIBLE_STATES
      }
    }.merge(base_query)
  end
end
