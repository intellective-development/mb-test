class SupplierAPIV2::ShipmentEndpoint < BaseAPIV2
  helpers do
    def current_supplier
      return @current_supplier = Supplier.find(params[:supplier_id]) if ENV['ENV_NAME'] != 'master' && params[:supplier_id].present?

      super
    end

    def price_filter(lower_price, current_variant)
      "price <= #{current_variant.price}" if ActiveModel::Type::Boolean.new.cast(lower_price)
    end

    def avoid_presale_and_backorder_change(shipment, desired_state)
      error!({ error: "Shipment cannot be transitioned to #{desired_state} because it is a #{shipment.state}." }, 403) if shipment.pre_sale? || shipment.back_order?
    end

    def handle_shipment_state_change(shipment, data)
      shipment.create_metadata unless shipment.metadata
      shipment.metadata.update_attribute(:driver_id, data[:driver_id]) if data.key?(:driver_id)

      # this transition has alredy happened
      return true if shipment.state == data[:state]

      begin
        case data[:state]
        when 'confirmed'
          avoid_presale_and_backorder_change(shipment, data[:state])
          # When shipment supports dsp flipper its data will have a "use_delivery_service" key present
          # we need to use this value even when nil to set use_delivery_service [TECH-1948].
          shipment.use_delivery_service = data[:use_delivery_service] || false if data.key?('use_delivery_service')
          shipment.delivery_service_id = data[:delivery_service_id] if data.key?('delivery_service_id')
          shipment.delivery_estimate = SelectDeliveryEstimateService.new(data[:delivery_estimate][:min], data[:delivery_estimate][:max]).call if data[:delivery_estimate].present?

          shipment.save if shipment.changed?

          shipment.confirm!
        when 'en_route'
          avoid_presale_and_backorder_change(shipment, data[:state])
          shipment.create_tracking_detail(reference: data[:tracking_number], carrier: data[:shipping_provider]) if data[:tracking_number].present? && data[:shipping_provider].present?
          shipment.start_delivery!
        when 'exception'
          exception_metadata = {}
          exception_metadata[:type]        = data[:exception][:type]
          exception_metadata[:description] = data[:exception][:description]
          exception_metadata[:metadata]    = data[:exception][:metadata]
          shipment.transition_to!(:exception, exception_metadata)
        when 'scheduled'
          avoid_presale_and_backorder_change(shipment, data[:state])
          shipment.schedule!
        when 'delivered'
          avoid_presale_and_backorder_change(shipment, data[:state])
          metadata_updates = {}
          metadata_updates[:delivered_at]       = Time.zone.now
          metadata_updates[:signed_by_name]     = data[:signed_by_name] if data[:signed_by_name].present?
          shipment.metadata.update(metadata_updates)

          shipment.create_tracking_detail(reference: data[:tracking_number], carrier: data[:shipping_provider]) if data[:tracking_number].present? && data[:shipping_provider].present?

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
  end

  namespace :bulk_update do
    params do
      requires :shipments, type: Array do
        requires :uuid, type: String
        optional :state, type: String, values: %w[confirmed scheduled delivered exception en_route]
        optional :delivery_estimate, type: Hash do
          requires :min, type: Integer, allow_blank: false
          requires :max, type: Integer, allow_blank: false
        end
        optional :use_delivery_service, type: Boolean
        optional :delivery_service_id,  type: Integer
        optional :scheduled_for,        type: String
        optional :driver_id,            type: Integer
        optional :signed_by_name,       type: String
        optional :tracking_number,      type: String
        optional :shipping_provider,    type: String
        all_or_none_of :shipping_provider, :tracking_number
        optional :exception, type: Hash do
          requires :type,        type: String, allow_blank: false
          requires :description, type: String, allow_blank: false
        end
      end
    end
    put do
      begin
        params[:shipments].each do |shipment_params|
          shipment = Shipment.find_by(uuid: shipment_params[:uuid])
          error!('Shipment not found', 404) if shipment.nil?
          handle_shipment_state_change(shipment, shipment_params)
        end
      rescue StandardError => e
        Rails.logger.error("Error during shipment bulk update: #{e.message}")
        error!('Internal error', 500)
      end

      { success: true }
    end
  end

  namespace :order do
    params do
      requires :shipment_id, type: String
    end
    before do
      authorize! if ENV['ENV_NAME'] == 'master' || params[:supplier_id].blank?

      @shipment   = current_supplier.shipments.includes(:shipment_amount).find_by(uuid: params[:shipment_id])
      @shipment ||= Shipment.includes(:shipment_amount).where(supplier_id: current_supplier_ids).find_by(uuid: params[:shipment_id])

      error!('Order not found', 404) if @shipment.nil?
    end

    route_param :shipment_id do
      desc 'Load a single shipment.'
      get do
        present @shipment, with: SupplierAPIV2::Entities::Shipment
      end

      namespace :extras do
        params do
          requires :body, type: Hash
        end
        desc 'Add extras fields'
        put do
          params[:body].each do |key, extra|
            supplier_extra = ShipmentSupplierExtra.find_or_create_by(supplier_id: @shipment.supplier.id, shipment_id: @shipment.id, field_id: key)
            supplier_extra.value = extra
            supplier_extra.save!
          end
        end
      end

      namespace :substitutes do
        desc 'Look for product substitute.'
        before do
          @shipment_supplier = @shipment&.supplier || current_supplier
          error!('Not available', 404) unless @shipment_supplier.allow_substitution?
        end
        route_param :sku do
          get do
            current_variant = Variant.find_by(sku: params[:sku])
            if params[:query].empty?
              product_types = current_variant&.product&.product_type&.type_tree_ordered&.map(&:id)
              @substitutes = Variant.joins(%i[product_size_grouping supplier inventory])
                                    .merge(ProductSizeGrouping.where('product_groupings.product_type_id IN (?)', product_types))
                                    .where('suppliers.id = ?', @shipment_supplier.id)
                                    .where(price_filter(params[:lower_price], current_variant)).limit(50)
              @substitutes = product_types.flat_map { |pt| @substitutes.select { |s| s.product_size_grouping.product_type.id == pt } }
            else
              @substitutes = Variant.joins(%i[product supplier inventory])
                                    .where('unaccent(products.name) iLIKE unaccent(?)', "%#{params[:query]}%")
                                    .where('suppliers.id = ?', @shipment_supplier.id)
                                    .where(price_filter(params[:lower_price], current_variant)).limit(50)
            end
            error! :not_found, 404 if @substitutes.nil?
            present @substitutes, with: SupplierAPIV2::Entities::Variant
          end
        end

        desc 'Update product substitute'
        put do
          order_item = @shipment.order_items.find { |oi| oi.id == params[:orderItemId] }
          error! :not_found, 404 if order_item.nil?

          quantity_to_replace = params[:quantity_to_replace]
          quantity_to_replace = order_item.quantity if params[:quantity_to_replace].nil? || order_item.quantity < params[:quantity_to_replace].to_i

          substitute_variant = Variant.find_by(sku: params[:sku], supplier_id: current_supplier.id)
          error! :not_found, 404 if substitute_variant.nil?

          error!('Substitute variant is the same as original', 400) if substitute_variant.sku == order_item.variant.sku && quantity_to_replace == params[:quantity].to_i

          order_item_substitutions = Substitution.where(original_id: order_item.id).where.not(status: :cancelled)
          error!('Pending substitution already exists', 400) if order_item_substitutions.count.positive?

          substitute_order_item = OrderItemTemp.new(variant: substitute_variant, quantity: params[:quantity], price: substitute_variant.price, tax_address: @shipment.address, tax_rate_id: order_item.tax_rate_id)
          substitute_order_item.save!

          if quantity_to_replace < order_item.quantity
            remaining_order_item = OrderItemTemp.new(variant: order_item.variant, quantity: order_item.quantity - quantity_to_replace, price: order_item.price, tax_address: @shipment.address, tax_rate_id: order_item.tax_rate_id)
            remaining_order_item.save!
          end

          substitution = Substitution.create(shipment: @shipment, substitute: substitute_order_item, original: order_item, remaining_item: remaining_order_item)
          @shipment.comments.create(
            note: format('You proposed a substitution: %s. Now waiting for Minibar Customer Support to confirm change with customer.', substitution.description),
            created_by: resource_owner.id,
            user_id: @shipment.order.user_id,
            posted_as: :supplier
          )

          @shipment.recalculate_and_apply_taxes

          present @shipment, with: SupplierAPIV2::Entities::Shipment
        end
      end

      namespace :comments do
        desc 'Load comments associated with a single shipment'
        get do
          present @shipment.comments.order(created_at: :asc), with: SupplierAPIV2::Entities::Comment, supplier_timezone: current_supplier.timezone
        end
        desc 'Post a new comment'
        params do
          requires :body, type: String
        end
        post do
          @comment = @shipment.comments.new(
            note: params[:body],
            created_by: resource_owner.id,
            user_id: @shipment.order.user_id,
            posted_as: :supplier
          )

          if @comment.save
            present @comment, with: SupplierAPIV2::Entities::Comment, supplier_timezone: current_supplier.timezone
          else
            error!('Error adding comment.', 400)
          end
        end

        route_param :comment_id do
          params do
            requires :file, type: File, desc: 'Image or document to be attached to comment'
          end

          desc 'Add attachment to order comment'
          post '/attachment' do
            file = Paperclip.io_adapters.for(params[:file][:tempfile])
            file.original_filename = params[:file][:filename]

            comment = Comment.find(params[:comment_id])
            comment.file = file
            comment.save!
          end
        end
      end

      desc 'Load order adjustments associated with a single shipment.'
      get :adjustments do
        present :count,       @shipment.order_adjustments.size
        present :total,       @shipment.order_adjustments.to_a.sum { |adjustment| adjustment.amount * (adjustment.credit ? 1 : -1) }.to_f
        present :adjustments, @shipment.order_adjustments.order(created_at: :asc), with: SupplierAPIV2::Entities::Adjustment
      end

      desc 'Get invoice as html'
      get :pdf_html do
        ShipmentInvoiceService.new(@shipment).generate_invoice_html
      end

      desc 'Update a shipment - general this is adjusting its state and/or setting a delivery estimate.'
      params do
        optional :state, type: String, values: %w[confirmed scheduled delivered exception en_route]
        optional :delivery_estimate, type: Hash do
          requires :min, type: Integer, allow_blank: false
          requires :max, type: Integer, allow_blank: false
        end
        optional :use_delivery_service, type: Boolean
        optional :delivery_service_id,  type: Integer
        optional :scheduled_for,        type: String
        optional :driver_id,            type: Integer
        optional :signed_by_name,       type: String
        optional :tracking_number,      type: String
        optional :shipping_provider,    type: String
        all_or_none_of :shipping_provider, :tracking_number
        optional :exception, type: Hash do
          requires :type,        type: String, allow_blank: false
          requires :description, type: String, allow_blank: false
        end
      end

      put do
        error!('Missing exception info', 200) if params[:state] == 'exception' && params[:exception].blank?

        begin
          handle_shipment_state_change(@shipment, params)
        rescue OrderWorkflowError => e
          error!(e.message, 200)
        rescue StandardError => e
          Rails.logger.error("Unhandled error updating a shipment: #{e.message}")
          error!('Internal Server Error', 500)
        end

        @shipment.reload
        present @shipment, with: SupplierAPIV2::Entities::Shipment
      end

      namespace :actions do
        desc 'Charge a pre-sale or back-order shipment (ready for fulfillment)'
        put :charge do
          if Charges::ChargeOrderService.create_and_authorize_charges(@shipment.order, [@shipment])
            handle_shipment_state_change(@shipment, { state: 'confirmed' })
            @shipment.reload
            present @shipment, with: SupplierAPIV2::Entities::Shipment
          else
            error!("Could not charge customer on order #{@shipment.order.number}. We're already aware of it.", 400)
          end
        end
      end
    end
  end
end
