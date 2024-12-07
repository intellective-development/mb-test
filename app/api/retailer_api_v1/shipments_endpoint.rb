# frozen_string_literal: true

# Retailer shipments entity
class RetailerAPIV1::ShipmentsEndpoint < BaseAPIV2
  helpers do
    params :pagination do
      optional :page, type: Integer, default: 1
      optional :per_page, type: Integer, default: 20
    end

    params :sorting do
      optional :sort_column, type: String, values: %w[created_at state], default: 'created_at'
      optional :sort_direction, type: Symbol, values: %i[asc desc], default: :desc
    end

    params :filtering do
      optional :filters, type: Hash, default: {} do
        optional :date_range, type: Hash do
          optional :start, type: String
          optional :end, type: String
        end
        optional :states, type: Array
      end
    end

    def avoid_presale_and_backorder_change(shipment, desired_state)
      error!({ error: "Shipment cannot be transitioned to #{desired_state} because it is a #{shipment.state}." }, 403) if shipment.pre_sale? || shipment.back_order?
    end

    def handle_shipment_state_change(shipment, data)
      return true if shipment.state == data[:state]

      begin
        avoid_presale_and_backorder_change(shipment, data[:state])
        case data[:state]
        when 'confirmed'
          shipment.confirm!
        when 'en_route'
          shipment.start_delivery!
        when 'scheduled'
          shipment.schedule!
        when 'delivered'
          shipment.deliver!
          # Give some time to reindex take place and update active orders
          ShipmentDashboardNotificationWorker.perform_at(30.seconds.from_now, shipment.id)
        else
          raise Statesman::TransitionFailedError
        end
      rescue Statesman::TransitionFailedError, Statesman::InvalidTransitionError
        raise OrderWorkflowError, "Cannot transition order #{shipment.order.number} to '#{data[:state]}'"
      end
    end

    def find_or_create_user(name, email, storefront, supplier)
      account = RegisteredAccount.find_by(email: email)
      account ||= RegisteredAccount.create do |a|
        a.first_name = name.split(' ').try(:[], 0)
        a.last_name = name.split(' ').try(:[], 1) || "(#{supplier.display_name})"
        a.state = 'active'
        a.password = 'password'
        a.password_confirmation = 'password'
        a.storefront = storefront
      end

      account.create_user if account.user.nil?

      account.user
    end

    def create_comment(shipment, data)
      user = find_or_create_user(data[:author][:name], data[:author][:email], shipment.order.storefront, shipment.supplier)
      comment_params = {
        note: data[:note],
        user: user,
        posted_as: :supplier,
        liquid: true
      }
      comment_params[:external_file] = data[:file] if data[:file].present?

      comment = shipment.comments.create!(comment_params)

      effective_supplier = shipment.effective_supplier
      return if comment.blank? || effective_supplier.dashboard_type != Supplier::DashboardType::THREE_JMS

      Dashboard::Integration::ThreeJMSDashboard.new(effective_supplier).send_comment(shipment, comment)
    end

    def date_range
      date_start = params.dig(:filters, :date_range, :start)
      date_end = params.dig(:filters, :date_range, :end)
      date_start..date_end if date_start.present? && date_end.present?
    end

    def filter_query(shipments)
      query = shipments.clone
      query.where!(orders: { created_at: date_range }) if date_range

      if params[:sort_column].present?
        case params[:sort_column]
        when 'state'
          query.order!("shipments.state #{params[:sort_direction]}")
        else
          query.order!(
            Arel.sql("greatest(shipments.created_at, orders.completed_at) #{params[:sort_direction]}")
          )
        end
      end

      query.page(params[:page]).per(params[:per_page])
    end

    def response(shipments)
      header 'X-Total', shipments.total_count.to_s
      header 'X-Total-Pages', shipments.total_pages.to_s

      present shipments, with: RetailerAPIV1::Entities::Shipments
    end
  end

  namespace :shipments do
    params do
      use :filtering
      use :pagination
      use :sorting
    end

    get do
      supplier = Supplier.find(params[:supplier_id])
      delegatees = Supplier.where(delegate_supplier_id: supplier.id).pluck(:id)
      query = Shipment.joins(:order).where(supplier_id: delegatees << supplier.id)
      query.where!(state: params[:filters][:states]) if params[:filters][:states]
      response(filter_query(query))
    end

    route_param :shipment_id do
      before do
        supplier = Supplier.find(params[:supplier_id])
        _order_id, shipment_id = params[:shipment_id].split('_')

        @shipment = supplier.shipments.includes(:shipment_amount).find_by(id: shipment_id)
        error!('Shipment not found', 404) if @shipment.nil?
      end

      params do
        requires :shipment_id, type: String
      end

      desc 'Load a single shipment.'
      get do
        present @shipment, with: RetailerAPIV1::Entities::Shipment
      end
    end

    desc 'Bulk charge pre-sale or back-order shipments.'
    params do
      requires :shipments, type: Array, allow_blank: false do
        requires :id, type: Integer
        requires :supplier_id, type: Integer
      end
    end
    put :bulk_charge do
      errors = {}
      not_found_shipments = []
      params[:shipments].each do |shipment_params|
        supplier = Supplier.find(shipment_params[:supplier_id])
        shipment = supplier.shipments.find_by(id: shipment_params[:id])

        if shipment.nil?
          errors[shipment_params[:id].to_s.to_sym] = "Shipment with id #{shipment_params[:id]} not found for supplier #{shipment_params[:supplier_id]}"
          not_found_shipments << shipment_params[:id]
          next
        end

        response = Charges::ChargeOrderService.create_and_authorize_charges(shipment.order, [shipment])

        next if response

        message = 'Error when charging shipment'
        Rails.logger.error(message)
        errors[shipment_params[:id].to_s.to_sym] = message
      end

      shipment_ids = params[:shipments].map { |s| s[:id] } - not_found_shipments
      shipments = Shipment.includes(:shipment_amount, :shipping_method, :order_items, :comments).where(id: shipment_ids)
      shipments = RetailerAPIV1::Entities::Shipment.represent(shipments)

      response = { shipments: shipments }
      response[:errors] = errors unless errors.empty?

      response
    end

    namespace :bulk_update do
      desc 'Update a shipment - general this is adjusting its state and/or creating comments.'
      params do
        requires :shipments, type: Array, allow_blank: false do
          requires :id, type: Integer
          requires :supplier_id, type: Integer
          optional :state, type: String, values: %w[confirmed scheduled delivered en_route]
          optional :comment, type: Hash do
            optional :note, type: String
            optional :file, type: String
            requires :author, type: Hash do
              requires :name, type: String, allow_blank: false
              requires :email, type: String, allow_blank: false
            end
            at_least_one_of :note, :file
          end
        end
      end

      put do
        errors = {}
        not_found_shipments = []
        params[:shipments].each do |shipment_params|
          supplier = Supplier.find(shipment_params[:supplier_id])
          shipment = supplier.shipments.find_by(id: shipment_params[:id])

          if shipment.nil?
            errors[shipment_params[:id].to_s.to_sym] = "Shipment with id #{shipment_params[:id]} not found for supplier #{shipment_params[:supplier_id]}"
            not_found_shipments << shipment_params[:id]
            next
          end

          shipment.liquid = true
          handle_shipment_state_change(shipment, shipment_params) if shipment_params[:state].present?
          create_comment(shipment, shipment_params[:comment]) if shipment_params[:comment].present?
        rescue OrderWorkflowError => e
          message = "Error transitioning shipment state: #{e.message}"
          Rails.logger.error(message)
          errors[shipment_params[:id].to_s.to_sym] = message
        rescue StandardError => e
          message = "Unhandled error updating a shipment: #{e.message}"
          Rails.logger.error(message)
          errors[shipment_params[:id].to_s.to_sym] = message
        end

        shipment_ids = params[:shipments].map { |s| s[:id] } - not_found_shipments
        shipments = Shipment.includes(:shipment_amount, :shipping_method, :order_items, :comments).where(id: shipment_ids)
        shipments = RetailerAPIV1::Entities::Shipment.represent(shipments)

        response = { shipments: shipments }
        response[:errors] = errors unless errors.empty?

        response
      end
    end
  end
end
