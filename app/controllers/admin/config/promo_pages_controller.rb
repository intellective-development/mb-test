class Admin::Config::PromoPagesController < Admin::Config::BaseController
  def index
    @pages = PromoPage.all
  end

  def show
    @page = PromoPage.find(params[:id])
  end

  def new
    @page = PromoPage.new
  end

  def edit
    @page = PromoPage.find(params[:id])
  end

  def create
    @page = PromoPage.new(allowed_params)

    if @page.save
      redirect_to(admin_config_promo_pages_url, notice: 'Page was successfully created.')
    else
      render action: 'new'
    end
  end

  def deactivate
    @page = PromoPage.find(params[:id])
    @page.update_attribute(:deleted_at, Time.zone.now)
    redirect_to :back
  end

  def update
    @page = PromoPage.find(params[:id])

    if @page.update(allowed_params)
      redirect_to(admin_config_promo_pages_url, notice: 'Page was successfully updated.')
    else
      render action: 'edit'
    end
  end

  private

  def allowed_params
    params.require(:promo_page).permit(:name, :description, :promo_code, :blurb,
                                       :direct_link, :logo, :background_image)
  end
end
