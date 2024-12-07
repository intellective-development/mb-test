class Admin::Merchandise::Multi::VariantsController < Admin::BaseController
  def edit
    @product = Product.includes(:properties, :product_properties, prototype: :properties).find(params[:product_id])
    @suppliers = Supplier.order(:name).collect { |sup| [sup.name, sup.id] }
    form_info
  end

  def update
    @product = Product.find(params[:product_id])

    if @product.update(allowed_params)
      flash[:notice] = 'Successfully updated variants'
      redirect_to admin_merchandise_product_url(@product)
    else
      form_info
      render action: :edit
    end
  end

  private

  def allowed_params
    params.require(:product).permit!
  end

  def form_info
    @brands = Brand.all.collect { |b| [b.name, b.id] }
  end
end
