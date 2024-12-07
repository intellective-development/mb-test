class Admin::Merchandise::Images::ProductSizeGroupingsController < Admin::BaseController
  def edit
    @product_size_grouping  = ProductSizeGrouping.includes(:images).find(params[:id])
  end

  def update
    @product_size_grouping  = ProductSizeGrouping.find(params[:id])
    @product_size_grouping.set_image(params[:image_url]) if params[:image_url]

    if @product_size_grouping.update(allowed_params)
      redirect_to action: :show
    else
      render action: :edit
    end
  end

  def show
    @product_size_grouping = ProductSizeGrouping.includes(:images).find(params[:id])
  end

  private

  def allowed_params
    params.require(:product_size_grouping).permit!
  end
end
