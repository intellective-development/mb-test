class Admin::StorefrontFontsController < Admin::BaseController
  delegate      :sort_column, :sort_direction, to: :list_storefront_fonts
  helper_method :sort_column, :sort_direction
  before_action :load_storefront
  before_action :load_storefront_font, only: %i[show edit update destroy]

  def index
    @storefront_fonts = list_storefront_fonts.result
  end

  def new
    @storefront_font = StorefrontFont.new
  end

  def create
    @storefront_font = create_storefront_font.storefront_font

    redirect_to(action: :index) and return if create_storefront_font.success?

    flash[:error] = 'The storefront font could not be saved'
    render action: :new
  end

  def update
    redirect_to(action: :index) and return if update_storefront_font.success?

    flash[:error] = 'The storefront font could not be updated'
    render action: :edit
  end

  def destroy
    redirect_to(action: :index) and return if delete_storefront_font.success?

    flash[:error] = 'The storefront font could not be deleted'
    redirect_to(action: :index)
  end

  private

  def list_storefront_fonts
    ::StorefrontFonts::List.new(params).call
  end

  def create_storefront_font
    @create_storefront_font ||= ::StorefrontFonts::Create.new(storefront_font_params).call
  end

  def update_storefront_font
    ::StorefrontFonts::Update.new(@storefront_font, storefront_font_params).call
  end

  def load_storefront
    @storefront = Storefront.find(params[:storefront_id])
  end

  def load_storefront_font
    @storefront_font = StorefrontFont.find(params[:id])
  end

  def delete_storefront_font
    ::StorefrontFonts::Delete.new(@storefront_font).call
  end

  def storefront_font_params
    params.require(:storefront_font).permit(
      :name, :font_type, :font_file, :storefront_id
    )
  end
end
