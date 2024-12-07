class Admin::Merchandise::BrandsController < Admin::BaseController
  def index
    params[:page] ||= 1
    @brands = Brand.admin_grid(params)
                   .order('name ASC')
                   .page(pagination_page)
                   .per(pagination_rows)
  end

  def show
    @brand = Brand.find(params[:id])
  end

  def new
    @brand = Brand.new
  end

  def create
    @brand = Brand.new(allowed_params)
    if @brand.save
      flash[:notice] = 'Successfully created brand.'
      redirect_to admin_merchandise_brand_url(@brand)
    else
      render action: 'new'
    end
  end

  def edit
    @brand = Brand.find(params[:id])
  end

  def update
    @brand = Brand.find(params[:id])
    @brand.parent_brand_id = nil if params[:brand][:parent_brand_id].blank?
    params[:brand][:distributor_ids] ||= []
    if @brand.update(allowed_params)
      flash[:notice] = 'Successfully updated brand.'
      redirect_to admin_merchandise_brand_url(@brand)
    else
      render action: 'edit'
    end
  end

  def destroy
    @brand = Brand.find(params[:id])
    if @brand.product_size_groupings.exists?
      unknown_brand = Brand.find_by(name: 'Unknown Brand')
      @brand.product_size_groupings.each { |grouping| grouping.update(brand: unknown_brand) }
      flash[:alert] = 'Any groupings associated with the deleted brand are now associated with \'Unknown Brand\'.'
      @brand.destroy
    end
    redirect_to admin_merchandise_brands_url
  end

  private

  def allowed_params
    params.require(:brand).permit(:name, :description, :mobile_image, :web_image, :parent_brand_id, :sponsored, :tag_list, distributor_ids: [])
  end
end
