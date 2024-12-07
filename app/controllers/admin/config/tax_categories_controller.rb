class Admin::Config::TaxCategoriesController < Admin::Config::BaseController
  load_and_authorize_resource

  def index; end

  def show; end

  def new; end

  def edit; end

  def create
    if @tax_category.save
      redirect_to(admin_config_tax_categories_url, notice: 'Tax category was successfully created.')
    else
      render action: 'new'
    end
  end

  def update
    if @tax_category.update(tax_category_params)
      redirect_to(admin_config_tax_categories_url, notice: 'Tax category was successfully updated.')
    else
      render action: 'edit'
    end
  end

  private

  def tax_category_params
    params.require(:tax_category).permit(:name, :description, :purpose)
  end
end
