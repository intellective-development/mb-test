class Admin::Content::PlacementsController < Admin::BaseController
  def show
    @placement = ContentPlacement.find(params[:id])
  end

  def index
    @placements = ContentPlacement.order(:name)
                                  .page(params[:page] || 1)
                                  .per(params[:per_page] || 30)
  end

  def new
    @placement = ContentPlacement.new
    load_promotions
  end

  def create
    @placement = ContentPlacement.new(allowed_params)
    if @placement.save
      redirect_to(admin_content_placements_path, notice: 'Content Placement Created')
    else
      render action: :new
    end
  end

  def edit
    @placement = ContentPlacement.find(params[:id])
    load_promotions
  end

  def update
    @placement = ContentPlacement.find(params[:id])
    if @placement.update(allowed_params)
      redirect_to(admin_content_placements_path, notice: 'Content Placement Created')
    else
      render action: :edit
    end
  end

  def destroy; end

  private

  def load_promotions
    @promotions = Promotion.active
                           .at(Time.zone.now)
                           .order(:type, :internal_name)
                           .map { |p| ["#{p.type} - #{p.internal_name}", p.id] }
  end

  def allowed_params
    params.require(:content_placement).permit(:name, :default_promotion_id, :content_type)
  end
end
