class Admin::Merchandise::BundlesController < Admin::BaseController
  def index
    params[:page] ||= 1
    @bundles = Bundle.admin_grid(params)
                     .order('description ASC')
                     .page(pagination_page)
                     .per(pagination_rows)
  end

  def show
    @bundle = Bundle.find(params[:id])
  end

  def new
    form_info
    @bundle = Bundle.new
    @bundle.bundle_items = [BundleItem.new]
  end

  def create
    @bundle = Bundle.new(allowed_params)
    @bundle.source_type = params[:bundle][:source_type]
    @bundle.source_id = params[:bundle][:source_id]
    @bundle.bundle_items = parse_item_types
    @bundle.user_id = current_user.id
    if @bundle.save
      flash[:notice] = 'Successfully created bundle.'
      redirect_to edit_admin_merchandise_bundle_path(@bundle)
    else
      form_info
      render action: 'new'
    end
  end

  def edit
    form_info
    @bundle = Bundle.find(params[:id])
  end

  def update
    @bundle = Bundle.find(params[:id])
    @bundle.attributes = allowed_params
    @bundle.source_type = params[:bundle][:source_type]
    @bundle.source_id = params[:bundle][:source_id]
    @bundle.bundle_items = parse_item_types
    @bundle.user_id = current_user.id
    if @bundle.save
      flash[:notice] = 'Successfully updated bundle.'
      redirect_to edit_admin_merchandise_bundle_path(@bundle)
    else
      form_info
      render action: 'edit'
    end
  end

  def destroy
    @bundle = Bundle.find(params[:id])
    @bundle.destroy
    redirect_to admin_merchandise_bundles_url
  end

  private

  def parse_item_types
    item_types = params[:bundle][:item_type]
    item_ids = params[:bundle][:item_id]
    items = []
    item_types.each_with_index do |item_type, index|
      bundle_item = BundleItem.new
      bundle_item.item_type = item_type
      bundle_item.item_id = item_ids[index]
      items << bundle_item
    end
    items
  end

  def form_info
    @bundles = Bundle.order(:description).collect { |ts| [ts.description, ts.id] }
  end

  def allowed_params
    params.require(:bundle).permit(:name, :description, :category, :starts_at, :ends_at, :cocktail_id, :source, :bundle_items, :sponsored)
  end
end
