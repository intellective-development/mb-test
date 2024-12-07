class Admin::Config::StatesController < Admin::Config::BaseController
  def new
    @state = State.new
  end

  def edit
    @state = State.find(params[:id])
  end

  def create
    @state = State.new(allowed_params)

    if @state.save
      redirect_to(admin_config_region_pages_url, notice: 'Page was successfully created.')
    else
      render action: 'new'
    end
  end

  def update
    @state = State.find(params[:id])

    if @state.update(allowed_params) && @state.update_deliverable_cities(params['state']['deliverable_city_ids'])
      redirect_to(admin_config_region_pages_url, notice: 'Page was successfully updated.')
    else
      render action: 'edit'
    end
  end

  private

  def allowed_params
    params.require(:state)
          .permit(:name, :abbreviation, :described_as, :country_id, :slug, :statewide_shipping, deliverable_cities: [])
  end
end
