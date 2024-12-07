class Admin::Merchandise::ProductContentsController < Admin::BaseController
  helper_method :sort_column, :sort_direction
  respond_to :html, :json

  def index
    @product_contents = ProductContent.all.includes([:product_size_groupings])
  end

  def show
    @product_content = ProductContent.find(params[:id])
    respond_with(@product_content)
  end

  def new
    @product_size_grouping_id = params[:product_size_grouping_id]
    @product_content = ProductContent.new
    form_info
  end

  def create
    @product_content = ProductContent.new(allowed_params)

    if @product_content.save

      product_size_grouping = ProductSizeGrouping.find(params[:product_content][:product_size_grouping_id])
      product_size_grouping.product_content = @product_content
      product_size_grouping.save

      redirect_to action: :index, tab: params[:tab]
    else
      form_info
      flash[:error] = 'The content could not be saved'
      render action: :new
    end
  end

  def edit
    @product_content = ProductContent.find(params[:id])
    form_info
  end

  def update
    @product_content = ProductContent.find(params[:id])

    if @product_content.update(allowed_params)
      redirect_to action: :index, tab: params[:tab]
    else
      form_info
      render action: :edit
    end
  end

  ## activate and deactivate
  def destroy
    @product_content = ProductType.find(params[:id])
    @product_content.active = !@product_content.active?
    @product_content.save
    redirect_to action: :index
  end

  private

  def allowed_params
    params.require(:product_content).permit(:template, :primary_background_color,
                                            :secondary_background_color, :active,
                                            :video_mp4, :video_poster)
  end

  def form_info; end

  def sort_column
    ProductContent.column_names.include?(params[:sort]) ? params[:sort] : 'position'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end
end
