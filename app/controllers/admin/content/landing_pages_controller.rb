class Admin::Content::LandingPagesController < Admin::BaseController
  before_action :load_resource, only: %i[show edit destroy update]

  def index
    @landing_pages = LandingPage.all
  end

  def show; end

  def new
    @landing_page = LandingPage.new
  end

  def create
    @landing_page = LandingPage.new(attributes: landing_page_params, landing_page_content_attributes: landing_page_content_params)
    if @landing_page.save
      redirect_to admin_content_landing_pages_path, notice: 'Page was successfully created.'
    else
      redirect_to new_admin_content_landing_page_path, notice: @landing_page.errors.full_messages.join(', ')
    end
  end

  def edit; end

  def destroy
    if @landing_page.destroy
      redirect_to admin_content_landing_pages_path, notice: 'Page was successfully deleted.'
    else
      redirect_to admin_content_landing_pages_path, notice: 'Something went wrong.'
    end
  end

  def update
    if @landing_page.update(attributes: landing_page_params, landing_page_content_attributes: landing_page_content_params)
      redirect_to(admin_content_landing_pages_path, notice: 'Page was successfully updated.')
    else
      redirect_to edit_admin_content_landing_page_path, notice: @landing_page.errors.full_messages.join(', ')
    end
  end

  private

  def load_resource
    @landing_page = LandingPage.find(params[:id])
  end

  def landing_page_params
    params.require(:landing_page).permit(:permalink)
  end

  def landing_page_content_params
    params.require(:content).permit(:headline, :subheadline_1, :subheadline_2, :page_title, :legal, :meta_description)
  end
end
