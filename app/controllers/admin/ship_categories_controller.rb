class Admin::ShipCategoriesController < Admin::BaseController
  delegate      :sort_column, :sort_direction, to: :list_ship_categories
  helper_method :sort_column, :sort_direction
  before_action :load_ship_category, only: %i[edit update destroy]

  def index
    load_ship_categories
  end

  def new
    @ship_category = ShipCategory.new
  end

  def create
    @ship_category = create_ship_category.ship_category

    if create_ship_category.success?
      redirect_to action: :index
    else
      flash[:error] = 'The ship category could not be saved'
      render action: :new
    end
  end

  def update
    if update_ship_category.success?
      redirect_to action: :index
    else
      flash[:error] = 'The ship category could not be updated'
      render action: :edit
    end
  end

  def destroy
    if destroy_ship_category.success?
      redirect_to action: :index
    else
      load_ship_categories

      render action: :index
    end
  end

  private

  def load_ship_categories
    @ship_categories = list_ship_categories.result
  end

  def list_ship_categories
    @list_ship_categories ||= ::ShipCategories::List.new(params).call
  end

  def create_ship_category
    @create_ship_category ||= ::ShipCategories::Create.new(ship_category_params).call
  end

  def update_ship_category
    ::ShipCategories::Update.new(@ship_category, ship_category_params).call
  end

  def destroy_ship_category
    ::ShipCategories::Destroy.new(@ship_category).call
  end

  def load_ship_category
    @ship_category = ShipCategory.find(params[:id])
  end

  def ship_category_params
    params.require(:ship_category).permit(:name, :pim_name)
  end
end
