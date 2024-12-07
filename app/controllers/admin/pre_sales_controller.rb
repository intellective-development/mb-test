class Admin::PreSalesController < Admin::BaseController
  delegate      :sort_column, :sort_direction, to: :list_pre_sales
  helper_method :sort_column, :sort_direction
  before_action :load_pre_sale, only: %i[edit update toggle_status orders]
  before_action :load_suppliers, only: %i[new create edit update]

  include Admin::PreSalesMethods

  def index
    params[:status] = %w[active] unless params[:status].present?
    load_pre_sales
  end

  def new
    @pre_sale            = PreSale.new
    @product_order_limit = ProductOrderLimit.new

    @state_product_order_limits       = []
    @supplier_product_order_limits    = []
  end

  def create
    @pre_sale = create_pre_sale.pre_sale

    if create_pre_sale.success?
      create_variants
      return redirect_to action: :index
    end

    @product_order_limit = @pre_sale.product_order_limit

    @state_product_order_limits    = build_state_product_order_limits(pre_sale_params)
    @supplier_product_order_limits = build_supplier_product_order_limits(pre_sale_params)

    flash[:error] = 'The Pre sale could not be created'
    render action: :new
  end

  def edit
    @product_order_limit           = @pre_sale.product_order_limit
    @state_product_order_limits    = @product_order_limit.state_product_order_limits
    @supplier_product_order_limits = @product_order_limit.supplier_product_order_limits
  end

  def update
    if update_pre_sale(pre_sale_params).success?
      update_variants
      return redirect_to action: :index
    end

    @product_order_limit = @pre_sale.product_order_limit

    @state_product_order_limits    = build_state_product_order_limits(pre_sale_params)
    @supplier_product_order_limits = build_supplier_product_order_limits(pre_sale_params)

    flash[:error] = 'The Pre sale could not be updated'
    render action: :edit
  end

  def toggle_status
    new_status = @pre_sale.active? ? 'inactive' : 'active'

    flash[:error] = 'The Pre sale could not be updated' unless @pre_sale.update({ status: new_status })

    redirect_to action: :index
  end

  def orders
    @orders = OrderItem.includes(:order)
                       .joins(:variant, :shipment)
                       .merge(Shipment.paid)
                       .where(variants: { id: Variant.where(product: @pre_sale.product) })
                       .where('shipments.created_at >= ?', @pre_sale.starts_at)
                       .order('order_items.id')
  end

  private

  def load_pre_sales
    @pre_sales = list_pre_sales.result
  end

  def list_pre_sales
    @list_pre_sales ||= ::PreSales::List.new(params).call
  end

  def load_pre_sale
    @pre_sale = PreSale
                .includes(product_order_limit: [state_product_order_limits: [:state], supplier_product_order_limits: [:supplier]])
                .find(params[:id])
  end

  def create_pre_sale
    @create_pre_sale ||= ::PreSales::Create.new(pre_sale_params.to_h).call
  end

  def update_pre_sale(update_params)
    @update_pre_sale ||= ::PreSales::Update.new(@pre_sale, update_params.to_h).call
  end

  def create_variants
    ::PreSales::UpdateVariants.new(@pre_sale).call
  end

  def update_variants
    ::PreSales::UpdateVariants.new(@pre_sale).call
  end
end
