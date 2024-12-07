class Admin::Fulfillment::SubstitutionsController < Admin::Fulfillment::OrdersController
  before_action :load_order
  before_action :set_onus, only: %i[new create_with_variant]

  def new
    @substitution = Substitution.new
    @order_item = OrderItem.find params[:order_item_id]
    @current_supplier = @order_item.shipment.supplier
    @variant = Variant.new
    error!('Not available', 404) unless @current_supplier.allow_substitution?
    if params[:search_term].nil? || params[:search_term].empty?
      current_variant = Variant.find_by(sku: @order_item.variant.sku)
      product_types = current_variant&.product&.product_type&.type_tree_ordered&.map(&:id)
      @substitutions = Variant.includes(:inventory, product: %i[hierarchy_category product_size_grouping], product_size_grouping: %i[product_type hierarchy_category])
                              .joins(%i[product_size_grouping supplier inventory])
                              .merge(ProductSizeGrouping.where('product_groupings.product_type_id IN (?)', product_types))
                              .where('suppliers.id = ?', @current_supplier.id)
                              .limit(100)
      @substitutions = product_types.flat_map { |pt| @substitutions.select { |s| s.product_size_grouping.product_type.id == pt } }
    else
      @substitutions = Variant.includes(:inventory, product: %i[product_size_grouping hierarchy_category])
                              .joins(%i[product supplier inventory])
                              .where('unaccent(products.name) iLIKE unaccent(?)', "%#{params[:search_term]}%")
                              .where('suppliers.id = ?', @current_supplier.id)
                              .limit(100)
    end
    error! :not_found, 404 if @substitutions.nil?
  end

  def create
    order_item = OrderItem.find params[:subs][:order_item_id]

    create_substitution(order_item, params[:subs][:custom_price].to_f, params[:subs])

    flash[:notice] = 'Substitution created.'
    redirect_to action: 'edit', controller: 'admin/fulfillment/orders', id: @order.number
  end

  def create_with_variant
    @substitution = Substitution.new
    @order_item = OrderItem.find params[:order_item_id]
    @current_supplier = @order_item.shipment.supplier

    # Variant
    @variant = @current_supplier.variants.new(variant_params.merge({ inventory: Inventory.new(count_on_hand: params[:inventory].to_i) }))
    @variant.errors.add(:name, "can't be blank") if variant_params[:name].blank? # variant.name is PG's name so we need to be custom here

    # create stub product in order to form item_volume to search for
    product = parse_product_volume(@order_item.product.dup)

    # Product
    @product = Product.find_by(name: variant_params[:name], item_volume: product.item_volume)
    if @product.nil?
      @product = product
      @product.name = variant_params[:name]
      @product.product_size_grouping = nil
      @product.upc = nil
    end

    # Grouping
    @grouping = @product.product_size_grouping || ProductSizeGrouping.build_from_product(@product)
    @grouping.product_type ||= @order_item.product.product_type
    @grouping.hierarchy_category ||= @order_item.product.hierarchy_category

    # Relations
    @variant.product = @product
    @product.product_size_grouping = @grouping

    # Adding this block so stack trace is clear on where the error is
    begin
      is_variant_valid = @variant.valid?
      is_product_valid = @product.valid?
      is_grouping_valid = @grouping.valid?
    rescue StandardError => e
      Rails.logger.error "Error creating variant: #{e.message}"
      is_variant_valid = is_product_valid = is_grouping_valid = false
    end

    if is_variant_valid && is_product_valid && is_grouping_valid && @grouping.save && @product.save && @variant.save
      sub_params = params.slice(:quantity, :quantity_to_replace, :sku, :onus)

      create_substitution(@order_item, @variant.price, sub_params)

      flash[:notice] = 'Variant and substitution created successfully'
      redirect_to action: 'edit', controller: 'admin/fulfillment/orders', id: @order.number and return
    end

    @variant.inventory = nil
    flash[:alert] = 'There were errors trying to create the variant.'
    @substitutions = Variant.joins(%i[product supplier inventory])
                            .where('unaccent(products.name) iLIKE unaccent(?)', "%#{params[:search_term]}%")
                            .where('suppliers.id = ?', @current_supplier.id)
                            .limit(100)
    render action: :new
  end

  # TODO: make sure substitutions do not recalculate tips
  def accept
    find_substitution.confirm(current_user.id, params[:onus])
    flash[:notice] = 'Substitution confirmed.'
    redirect_to action: 'edit', controller: 'admin/fulfillment/orders', id: @order.number
  end

  def reject
    find_substitution.cancel current_user.id
    flash[:notice] = 'Substitution cancelled.'
    redirect_to action: 'edit', controller: 'admin/fulfillment/orders', id: @order.number
  end

  protected

  def variant_params
    params.permit(:sku, :name, :price)
  end

  def find_substitution
    Substitution.find(params[:id])
  end

  def load_order
    @order = Order.find(params[:order_id])
  end

  def set_onus
    @onus_options = [%w[Customer off], %w[Minibar on]]
  end

  def parse_product_volume(product)
    unless params[:volume].nil?
      volume = params[:volume]
      product.item_volume = volume
      volume = volume.split(',')
      if volume.size > 1
        parsed_container = volume.first.split(/(?<=\d)(?=[A-Za-z])/)
        product.container_count = parsed_container.first
        product.container_type = parsed_container.last if parsed_container.size > 1
        parsed_volume = volume.last.strip.split(' ')
        product.container_type = parsed_volume.last if parsed_volume.size > 1
        parsed_volume = parsed_volume.first.split(/(?<=\d)(?=[A-Za-z])/)
      else
        parsed_volume = volume.first.split(/(?<=\d)(?=[A-Za-z])/)
      end
      product.volume_value = parsed_volume.first
      product.volume_unit = parsed_volume.last if parsed_volume.size > 1
    end
    product
  end

  def create_substitution(order_item, custom_price, sub_params)
    if order_item.nil?
      flash[:alert] = 'Order Item not found'
      return redirect_to new_admin_fulfillment_order_substitution_path(@order.number, order_item_id: order_item.id)
    end

    if custom_price.negative?
      flash[:alert] = 'Price must be higher than 0'
      return redirect_to new_admin_fulfillment_order_substitution_path(@order.number, order_item_id: order_item.id)
    end

    @shipment = order_item.shipment
    current_supplier = @shipment.supplier

    quantity = sub_params[:quantity].to_i
    quantity_to_replace = sub_params[:quantity_to_replace].to_i if sub_params[:quantity_to_replace].present?
    quantity_to_replace = order_item.quantity if quantity_to_replace.nil? || order_item.quantity < quantity_to_replace.to_i
    substitution_params = {
      shipment: @shipment,
      order_item: order_item,
      sku: sub_params[:sku],
      quantity: quantity,
      quantity_to_replace: quantity_to_replace,
      custom_price: custom_price,
      supplier_id: current_supplier.id
    }
    create_substitution_service = SubstitutionService.new(substitution_params)

    substitute_variant = create_substitution_service.get_substitute_variant

    if substitute_variant.nil?
      flash[:alert] = 'Substitute variant not found'
      return redirect_to new_admin_fulfillment_order_substitution_path(@order.number, order_item_id: order_item.id)
    end

    if substitute_variant.sku == order_item.variant.sku && quantity_to_replace == quantity
      flash[:alert] = 'Substitute variant is the same as original'
      return redirect_to new_admin_fulfillment_order_substitution_path(@order.number, order_item_id: order_item.id)
    end

    order_item_substitutions = create_substitution_service.get_order_item_substitutions

    if order_item_substitutions.count.positive?
      flash[:alert] = 'Pending substitution already exists'
      return redirect_to new_admin_fulfillment_order_substitution_path(@order.number, order_item_id: order_item.id)
    end

    substitute_order_item = create_substitution_service.get_substitute_order_item(substitute_variant)

    remaining_order_item = create_substitution_service.get_remaining_order_item

    substitution = create_substitution_service.get_substitution(@shipment, substitute_order_item, order_item, remaining_order_item)
    @shipment.comments.create(
      note: format('You proposed a substitution: %s.', substitution.description),
      created_by: current_user.id,
      user_id: @shipment.order.user_id,
      posted_as: :minibar
    )
    substitution.confirm(current_user.id, sub_params[:onus])

    Segment::SendOrderUpdatedEventWorker.perform_async(@order.id, :substitution_created)
  end
end
