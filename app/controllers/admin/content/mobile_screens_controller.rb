class Admin::Content::MobileScreensController < Admin::BaseController
  before_action :load_mobile_screen, only: %i[show edit update]

  def show; end

  def index
    @mobile_screens = ::Content::MobileScreen.order(:name)
                                             .page(params[:page] || 1)
                                             .per(params[:per_page] || 30)
  end

  def new
    @mobile_screen = ::Content::MobileScreen.new
  end

  def create
    @mobile_screen = ::Content::MobileScreen.new(allowed_params)
    if @mobile_screen.save
      redirect_to(admin_content_mobile_screens_path, notice: 'Screen Created')
    else
      render action: :new
    end
  end

  def edit; end

  def update
    load_mobile_screen.update(allowed_params)

    redirect_to action: :edit, notice: 'Screen Updated'
  end

  def destroy; end

  private

  def load_mobile_screen
    @mobile_screen ||= ::Content::MobileScreen.find(params[:id])
  end

  def allowed_params
    params.require(:content_mobile_screen).permit(:name, :description, :active, :platform,
                                                  modules_attributes: %i[internal_name module_type priority logged_in logged_out content id section_id config _destroy])
  end
end
