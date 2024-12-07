class Admin::Config::RegionPagesController < Admin::Config::BaseController
  def index
    @states = State.all.order(name: :asc)
    @regions = Region.all
  end

  def show
    @region = Region.find(params[:id])
  end

  def new
    @region = Region.new
  end

  def edit
    @region = Region.find(params[:id])
  end

  def create
    @region = Region.new(allowed_params)

    if @region.save
      redirect_to(admin_config_region_pages_url, notice: 'Page was successfully created.')
    else
      render action: 'new'
    end
  end

  def update
    @region = Region.find(params[:id])

    if @region.update(allowed_params)
      redirect_to(admin_config_region_pages_url, notice: 'Page was successfully updated.')
    else
      render action: 'edit'
    end
  end

  private

  def allowed_params
    params.require(:region)
          .permit(:name, :description, :visible, :position, :state_id, header_image_attributes: %i[file _destroy id])
  end
end
