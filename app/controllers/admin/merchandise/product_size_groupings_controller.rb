class Admin::Merchandise::ProductSizeGroupingsController < Admin::BaseController
  helper_method :sort_column, :sort_direction, :image_groups

  respond_to :html, :json, :js
  authorize_resource

  def index
    query = params[:query].presence || '*'
    params[:state] ||= 'active_and_inactive'

    @groupings = ProductSizeGrouping.search(
      query,
      fields: ['name'],
      includes: %i[images product_type],
      where: { active: true },
      order: { sort_column.to_sym => sort_direction.to_sym },
      per_page: 10,
      page: pagination_page
    )
    @groupings_size = @groupings.response.dig('hits', 'total')
  end

  def show
    @product_grouping = ProductSizeGrouping.includes(product_properties: [:property]).find(params[:id])

    respond_to do |format|
      format.html
      format.json { render json: AdminAPIV1::Entities::ProductForm.represent(@grouping).to_json }
    end
  end

  def edit
    @product_grouping = ProductSizeGrouping.find(params[:id])
    load_products

    form_info
  end

  def new
    @product_grouping = ProductSizeGrouping.new
    @prototypes               = Prototype.all.collect { |pt| [pt.name, pt.id] }
    @all_properties           = Property.where(identifing_name: ProductSizeGrouping::WHITELIST_PROPERTIES)
    @select_tax_category      = TaxCategory.all.collect { |sc| [sc.name, sc.id] }
  end

  def create
    @product_grouping = ProductSizeGrouping.new

    @product_grouping.images_attributes = images_params

    @product_grouping.meta_description = @product_grouping.name
    @product_grouping.attributes = allowed_params

    @product_grouping.tag_list = begin
      allowed_params[:tag_list].split
    rescue StandardError
      ''
    end

    if @product_grouping.save && activate_product_grouping?(params)
      redirect_to admin_merchandise_product_size_grouping_url(@product_grouping)
    else
      form_info

      render action: :new
    end
  end

  def update
    @product_grouping = ProductSizeGrouping.find(params[:id])

    @product_grouping.images_attributes = images_params

    @product_grouping.meta_description = @product_grouping.name
    @product_grouping.attributes = allowed_params

    @product_grouping.tag_list = begin
      allowed_params[:tag_list].split
    rescue StandardError
      ''
    end

    @product_grouping.business_remitted = allowed_params[:business_remitted]

    removed_properties = params[:product_size_grouping][:product_properties_attributes].values.select { |p| p[:_destroy].to_i == 1 }
    ProductProperty.delete(removed_properties.map { |p| p[:id] })
    params[:product_size_grouping][:product_properties_attributes].permit!.to_h.each do |attribute|
      property_attributes = attribute.last
      not_removed = property_attributes[:_destroy].to_i.zero?
      is_new = property_attributes[:id].nil?
      not_blank = property_attributes[:value].present?

      @product_grouping.product_properties.build(property_attributes.except(:_destroy)) if is_new && not_removed && not_blank
    end

    if @product_grouping.save && activate_product_grouping?(params)
      flash[:notice] = 'Successfully updated product.'
      redirect_to edit_admin_merchandise_product_size_grouping_url(@product_grouping)
    else
      load_products
      form_info

      render action: :edit
    end
  end

  def toggle_product_state
    @grouping = ProductSizeGrouping.find(params[:id])
    Product.find(params[:product_id]).toggle_activation
    redirect_to action: :show
  end

  def deactivate_product
    @grouping = ProductSizeGrouping.find(params[:id])
    Product.find(params[:product_id]).deactivate
    redirect_to action: :edit, tab: 'sizes'
  end

  def activate_product
    @grouping = ProductSizeGrouping.find(params[:id])
    Product.find(params[:product_id]).activate
    redirect_to action: :edit, tab: 'sizes'
  end

  def flag_product
    @grouping = ProductSizeGrouping.find(params[:id])
    Product.find(params[:product_id]).flag
    redirect_to action: :edit, tab: 'sizes'
  end

  def reindex
    @grouping = ProductSizeGrouping.find(params[:id])
    @grouping.reindex_async
    @grouping.products.find_each(&:reindex_async)
    @grouping.variants.find_each(&:reindex_async)

    flash[:notice] = "Reindexing #{@grouping.name}. This should be done shortly."
    redirect_to action: :show
  end

  def child_products
    @product_grouping = ProductSizeGrouping.find(params[:id])
    @products = Product.not_merged.where(product_grouping_id: @product_grouping.id).order('volume_value ASC').page(params[:page] || 1).per(20)
    respond_to do |format|
      format.html { render partial: 'sizes' }
    end
  end

  def remove_image
    @grouping = ProductSizeGrouping.find(params[:id])
    @grouping.images&.first&.delete
    redirect_to action: :edit, tab: 'edit'
  end

  def remove_child_product_images
    @grouping = ProductSizeGrouping.includes(products: [:images]).find(params[:id])
    @grouping.products.each do |product|
      product.images.destroy_all
    end
    redirect_to action: :edit, tab: 'sizes'
  end

  private

  def allowed_params
    params.require(:product_size_grouping).permit(
      :name,
      :default_search_hidden,
      :description,
      :product_type_id,
      :hierarchy_subtype_id,
      :hierarchy_type_id,
      :hierarchy_category_id,
      :meta_description,
      :brand_id,
      :permalink,
      :set_keywords,
      :tag_list,
      :business_remitted,
      :master,
      images_attributes: %i[photo photo_from_link id _destroy],
      product_properties_attributes: %i[property_id description id _destroy]
    )
  end

  def images_params
    ::NestedAttributesParameters.new(allowed_params[:images_attributes] || {})
  end

  def form_info
    @prototypes               = Prototype.all.collect { |pt| [pt.name, pt.id] }
    @all_properties           = Property.where(identifing_name: ProductSizeGrouping::WHITELIST_PROPERTIES)
    @select_tax_category      = TaxCategory.all.collect { |sc| [sc.name, sc.id] }
    @suppliers = Supplier.order(:name)
  end

  def load_products
    @products = Product.not_merged.where(product_grouping_id: @product_grouping.id).order('volume_value ASC').page(params[:page] || 1).per(20)
    @active_tab = params[:tab] || 'edit'
    @select_tax_category = TaxCategory.all.collect { |sc| [sc.name, sc.id] }
  end

  def sort_column
    ProductSizeGrouping.column_names.include?(params[:sort]) ? params[:sort] : 'name'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end

  def activate_product_grouping?(params = {})
    if params[:commit] == 'Update and Activate' && !@product.active? # if update and activate button
      @product_grouping.activate
    else
      true # default to true
    end
  end
end
