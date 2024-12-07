class Admin::Merchandise::GiftCardThemesController < Admin::BaseController
  before_action :set_theme_with_grouping, only: %i[show edit update toggle_active]

  def index
    @themes = GiftCardTheme.all
  end

  def show; end

  def new
    @theme = GiftCardTheme.new
  end

  def edit; end

  def create
    @theme = GiftCardTheme.new(gift_card_theme_params)
    if @theme.save
      flash[:notice] = 'Successfully created gift card theme.'
      redirect_to edit_admin_merchandise_gift_card_theme_path(@theme)
    else
      flash[:error] = 'The gift card theme could not be saved.'
      render action: 'new'
    end
  end

  def update
    @theme.assign_attributes(gift_card_theme_params)
    if @theme.save
      flash[:notice] = 'Successfully updated the gift card theme.'
      redirect_to edit_admin_merchandise_gift_card_theme_path(@theme)
    else
      flash[:error] = 'The gift card theme could not be updated.'
      render action: 'edit'
    end
  end

  def toggle_active
    @theme.active = !@theme.active
    @theme.save
    flash[:notice] = "Successfully #{@theme.active? ? 'activated' : 'deactivated'} the theme"
    redirect_to admin_merchandise_gift_card_themes_path
  end

  private

  def set_theme_with_grouping
    @theme = GiftCardTheme.includes(:product_size_grouping).find(params[:id])
    @product_grouping = @theme.product_size_grouping
  end

  def gift_card_theme_params
    image_params = %i[id photo photo_from_link]
    params.require(:gift_card_theme).permit(:name, :display_name, :storefront_id, :sellable_type, { images_attributes: image_params }, product_size_grouping_attributes: [:id, { images_attributes: image_params }], sellable_ids: [])
  end
end
