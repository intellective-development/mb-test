class Admin::Config::CitiesController < Admin::Config::BaseController
  def edit
    @city = City.find(params[:id])
  end

  def update
    @city = City.find(params[:id])

    if @city.update(allowed_params)
      redirect_to(admin_config_region_pages_url, notice: 'City was successfully updated.')
    else
      render action: 'edit'
    end
  end

  private

  def allowed_params
    params.require(:city)
          .permit(:name, :visible, :position, :region_id, header_image_attributes: %i[file _destroy id])
  end
end
