class Admin::Merchandise::ProductTypesController < Admin::BaseController
  helper_method :sort_column, :sort_direction
  respond_to :html, :json

  def index
    query = params[:query].presence || '*'
    params[:level] ||= { 'category' => 'true', 'type' => 'true', 'subtype' => 'true' }

    filters = {}
    filters[:level] = params[:level].keys.map { |level_name| ProductType::LEVEL_NAME_MAP[level_name.to_sym] }
    filters[:banner_featured_position] = { not: nil } if params['banner_featured']

    @product_types = ProductType.search(
      query,
      where: filters,
      order: [{ level: :asc }, { name: :asc }],
      per_page: pagination_rows,
      page: pagination_page
    )
  end

  def view_hierarchy
    @categories = ProductType.includes(:children).root.order(position: :asc)
  end

  def view_banner_preview
    user = current_user if params['use_user']
    search_options = {
      per_page: pagination_rows,
      page: pagination_page,
      featured: params['banner_featured'],

      # nils to unset the defaults
      supplier_ids: nil,
      has_banner_image: nil
    }

    @product_types = ProductTypeSearchService.search_popular(search_options, user)
  end

  def show
    @product_type = ProductType.find(params[:id])
    respond_with(@product_type)
  end

  def new
    @product_type = ProductType.new
    form_info
  end

  def create
    @product_type = ProductType.new(allowed_params)

    if @product_type.save
      redirect_to action: :index, tab: params[:tab]
    else
      form_info
      flash[:error] = 'The product_type could not be saved'
      render action: :new
    end
  end

  def edit
    @product_type = ProductType.find(params[:id])
    form_info
  end

  def update
    @product_type = ProductType.find(params[:id])

    if @product_type.update(allowed_params)
      redirect_to action: :index, tab: params[:tab]
    else
      form_info
      render action: :edit
    end
  end

  ## activate and deactivate
  def destroy
    @product_type = ProductType.find(params[:id])
    @product_type.active = !@product_type.active?
    @product_type.save
    redirect_to action: :index
  end

  private

  def form_info
    categories     = ProductType.root.includes(:children).order(position: :asc)
    product_types  = categories.map(&:children).flatten.sort_by { |o| [o.root&.name, o.position.to_i] }
    variatels      = ProductType.where(id: product_types.map(&:child_ids).flatten.uniq)

    @categories    = categories.page(1).per(pagination_rows)
    @product_types = Kaminari.paginate_array(product_types).page(1).per(pagination_rows)
    @variatels     = variatels.page(pagination_page).per(pagination_rows)

    @tab = (params[:tab] || (@product_type.try(:level) || 0) + 1).to_i
  end

  def sort_column
    ProductType.column_names.include?(params[:sort]) ? params[:sort] : 'position'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end

  def allowed_params
    params.require(:product_type).permit(:name, :description, :tax_code, :parent_id, :parent_parent_id, :position, :product_image, :banner_image, :banner_featured_position, :set_keywords, image_attributes: %i[photo_from_link photo _destroy id], ios_menu_image_attributes: [:file])
  end
end
