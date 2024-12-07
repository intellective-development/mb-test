class Admin::Fulfillment::ProductsController < Admin::Fulfillment::BaseController
  before_action :load_order

  def new
    load_resources
  end

  def create
    @order_item = OrderItem.new(order_item_params.merge({ shipment_id: @shipment.id }))

    save_order_item
  end

  def create_with_variant
    @current_supplier = @shipment.supplier

    # Variant
    @variant = @current_supplier.variants.new(variant_params.merge({ inventory: Inventory.new(count_on_hand: params[:inventory].to_i) }))
    @variant.errors.add(:name, "can't be blank") if variant_params[:name].blank? # variant.name is PG's name so we need to be custom here

    # Product
    @product = parse_product_volume(Product.new(
                                      name: variant_params[:name],
                                      product_size_grouping: nil,
                                      upc: nil
                                    ))

    # Grouping
    @grouping = @product.product_size_grouping || ProductSizeGrouping.build_from_product(@product)
    @grouping.product_type_id ||= params[:product_type_id]
    @grouping.hierarchy_category_id ||= params[:product_type_id]

    # Relations
    @variant.product = @product
    @product.product_size_grouping = @grouping

    if @variant.valid? && @product.valid? && @grouping.valid? && @grouping.save && @product.save && @variant.save
      @order_item = OrderItem.new(shipment_id: @shipment.id, variant_id: @variant.id, price: params[:price], quantity: params[:quantity])

      save_order_item
    else
      @variant.inventory = nil

      load_resources

      flash[:alert] = 'There were errors trying to create the variant.'
      render action: :new
    end
  end

  private

  def load_resources
    @order_item = OrderItem.new
    @product_types = ProductType.root.active
    @current_supplier = @shipment.supplier

    @variants = Variant.joins(%i[product supplier inventory]).where('suppliers.id = ?', @current_supplier.id)
    @variants = @variants.where('unaccent(products.name) iLIKE unaccent(?)', "%#{params[:search_term]}%") if params[:search_term].present?
    @variants = @variants.limit(100)
  end

  def save_order_item
    if @order_item.valid?
      @shipment.add_order_item(@order_item, current_user.id)
      flash[:notice] = 'Product added.'
      redirect_to action: 'edit', controller: 'admin/fulfillment/orders', id: @order.number
    else
      flash[:alert] = 'There were errors trying to add the product.'
      render action: :new
    end
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

  def variant_params
    params.permit(:sku, :name, :price)
  end

  def order_item_params
    params.require(:order_item).permit(:variant_id, :price, :quantity)
  end

  def load_order
    @order = Order.find(params[:order_id])
    @shipment = Shipment.find(params[:shipment_id])
  end
end
