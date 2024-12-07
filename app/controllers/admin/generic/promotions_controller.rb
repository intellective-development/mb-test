class Admin::Generic::PromotionsController < Admin::Generic::BaseController
  include Promotables

  def index
    @promotions = Promotion.where('ends_at > ?', 6.months.ago)
                           .order(:type, :internal_name, ends_at: :desc, starts_at: :desc)
                           .group_by(&:type)
  end

  def show
    @promotion = Promotion.find(params[:id])
  end

  def new
    form_info
    @promotion = Promotion.new
  end

  def create
    @promotion = Promotion.new(allowed_params)
    @promotion.type = params[:p_type]
    @promotion.errors.add(:base, 'please select promotion type') if params[:p_type].blank?

    if @promotion.errors.empty? && @promotion.save
      flash[:notice] = 'Successfully created promotion.'
      redirect_to admin_generic_promotion_url(@promotion)
    else
      form_info
      @promotables = promotable_options(@promotion.promotable_type)
      render action: 'new'
    end
  end

  def edit
    form_info
    @promotion = Promotion.find(params[:id])
    @promotables = promotable_options(@promotion.promotable_type)
  end

  def update
    @promotion = Promotion.find(params[:id])
    @promotion.promotion_items.clear if allowed_params[:promotable_ids] == [''] # clear if empty selection, doesn't clear otherwise

    if @promotion.update(allowed_params)
      flash[:notice] = 'Successfully updated promotion.'
      redirect_to admin_generic_promotion_url(@promotion)
    else
      form_info
      @promotables = promotable_options(@promotion.promotable_type)
      render action: 'edit'
    end
  end

  def destroy
    @promotion = Promotion.find(params[:id])
    @promotion.destroy
    flash[:notice] = 'Successfully destroyed promotion.'
    redirect_to admin_generic_promotions_url
  end

  private

  def allowed_params
    params.require(:promotion).permit(:id, :display_name, :internal_name, :starts_at, :ends_at, :content_placement_id,
                                      :active, :position, :image, :secondary_image, :target, :match_tag, :match_search, :match_product_type, :match_page_type,
                                      :match_category, :background_color, :priority, :promotable_type, :exclude_logged_in_user, :exclude_logged_out_user, :text_content,
                                      promotable_ids: [], promotion_filter_ids: [])
  end

  def form_info
    @promotion_types  = Promotion::PROMOTION_TYPES
    @tag_options      = ActsAsTaggableOn::Tag.joins(:taggings).where("taggings.taggable_type = 'ProductSizeGrouping'").select('DISTINCT tags.name').map(&:name).sort
    @category_options = ProductType.root.active.map(&:name)
    @placement_options = ContentPlacement.all.order(:name).map { |p| [p.name.to_s, p.id] }
  end
end
