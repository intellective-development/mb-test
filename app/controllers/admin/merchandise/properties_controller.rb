class Admin::Merchandise::PropertiesController < Admin::BaseController
  helper_method :sort_column, :sort_direction
  respond_to :html, :json
  def index
    @properties = Property.admin_grid(params)
                          .order("#{sort_column} #{sort_direction}")
                          .page(pagination_page)
                          .per(pagination_rows)
  end

  def new
    @property = Property.new
  end

  def create
    @property = Property.new(allowed_params)
    if @property.save
      redirect_to action: :index
    else
      flash[:error] = 'The property could not be saved'
      render action: :new
    end
  end

  def edit
    @property = Property.find(params[:id])
  end

  def update
    @property = Property.find(params[:id])
    if @property.update(allowed_params)
      redirect_to action: :index
    else
      render action: :edit
    end
  end

  def destroy
    @property = Property.find(params[:id])
    @property.active = false
    @property.save

    redirect_to action: :index
  end

  private

  def allowed_params
    params.require(:property).permit(:identifing_name, :display_name, :active, prototype_ids: [])
  end

  def sort_column
    Property.column_names.include?(params[:sort]) ? params[:sort] : 'identifing_name'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end
end
