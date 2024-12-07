class Admin::ProductRoutingsController < Admin::BaseController
  delegate      :sort_column, :sort_direction, to: :list_product_routings
  helper_method :sort_column, :sort_direction

  before_action :load_product_routing, only: %i[edit update toggle_status]

  def index
    @product_routings = list_product_routings.result
  end

  def new
    @product_routing = ProductRouting.new
  end

  def create
    @product_routing = create_product_routing.product_routing

    if create_product_routing.success?
      redirect_to action: :index
    else
      flash[:error] = 'The product routing could not be saved'
      render action: :new
    end
  end

  def update
    if update_product_routing(product_routing_params).success?
      redirect_to action: :index
    else
      flash[:error] = 'The product routing could not be updated'
      render action: :edit
    end
  end

  def toggle_status
    new_status = @product_routing.active? ? false : true

    if update_product_routing({ active: new_status }).success?
      redirect_to action: :index
    else
      flash[:error] = 'The product routing could not be updated'
      render action: :index
    end
  end

  private

  def list_product_routings
    @list_product_routings ||= ::ProductRoutings::List.new(params).call
  end

  def create_product_routing
    @create_product_routing ||= ::ProductRoutings::Create.new(product_routing_params).call
  end

  def update_product_routing(update_params)
    ::ProductRoutings::Update.new(@product_routing, update_params).call
  end

  def load_product_routing
    @product_routing = ProductRouting.find(params[:id])
  end

  def product_routing_params
    params.require(:product_routing).permit(:order_qty_limit, :comments, :engravable, :active, :starts_at,
                                            :ends_at, :storefront_id, :product_id, :supplier_id, states_applicable: [])
  end
end
