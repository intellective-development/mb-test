class Admin::Merchandise::ProductsController < Admin::BaseController
  helper_method :sort_column, :sort_direction, :product_type_list, :image_groups
  before_action :prevent_browser_caching
  before_action :load_suppliers, only: %i[edit update create_pre_sale]

  include Admin::PreSalesMethods

  respond_to :html, :json, :js
  authorize_resource

  def index
    params[:page] ||= 1
    query = params[:query].presence || '*'
    params[:state] ||= { active: true, pending: true }

    hierarchy  = params[:hierarchy].to_s.split(' ')
    subtype    = hierarchy[2..].join(' ') if hierarchy.length > 2 # wine white pinot grigio
    hierarchy  = [hierarchy[0], hierarchy[1], subtype]

    facets                       = {}
    facets[:brand]               = Brand.find(params[:brand_id]).name if params[:brand_id]
    facets[:state]               = params[:state].keys if params[:state] # this facet brought to you by abuse of checkboxes
    facets[:suppliers]           = params[:supplier_id] if params[:supplier_id].present?
    facets[:has_image]           = false if params[:no_image]
    facets[:has_grouping_image]  = false if params[:no_grouping_image]
    facets[:has_variants]        = true if params[:has_variants]

    if params[:in_stock] && params[:supplier_id].present?
      facets[:in_stock_supplier] = params[:supplier_id]
    elsif params[:in_stock]
      facets[:in_stock] = true
    end

    facets[:category]  = hierarchy[0] if hierarchy[0].present?
    facets[:type]      = hierarchy[1] if hierarchy[1].present?
    facets[:subtype]   = hierarchy[2] if hierarchy[2].present?

    order_by = case params[:order_by]
               when 'variants_desc'
                 { variant_count: :desc }
               when 'variants_asc'
                 { variant_count: :asc }
               else
                 { sort_column.to_sym => sort_direction.to_sym }
               end

    @products = Product.where.not(state: 'merged')
                       .search(query,
                               includes: %i[images product_type hierarchy_category],
                               where: facets,
                               match: :text_middle,
                               order: order_by,
                               per_page: pagination_rows,
                               page: pagination_page)
    @products_size = @products.response.dig('hits', 'total')
  end

  def show
    @product = Product.includes(:product_size_grouping, product_properties: [:property]).find(params[:id])
    @variants = filtered_variants(@product)

    respond_to do |format|
      format.html
      format.json { render json: AdminAPIV1::Entities::ProductForm.represent(@product).to_json }
    end
  end

  def new
    form_info
    @product                = Product.new
    @product_size_grouping  = @product.product_size_grouping = ProductSizeGrouping.find(params[:grouping])
    @product.name           = @product.product_size_grouping.name
    @variant                = @product.variants.build
  end

  def create
    @product = Product.new
    @product_size_grouping = @product.product_size_grouping = ProductSizeGrouping.find(params[:grouping])
    @product.name = @product.product_size_grouping.name # TODO: BC: Should be removed entirely eventually
    @product.variants_attributes = variants_params
    @product.images_attributes = images_params
    product_params[:limited_time_offer_data] = {} unless product_params[:limited_time_offer]&.to_bool
    @product.attributes = product_params

    if @product.save
      flash[:notice] = 'Success, You should create a variant for the product.'
      redirect_to admin_merchandise_product_url(@product)
    else
      form_info

      flash[:error] = 'The product could not be saved'
      render action: :new
    end
  end

  def edit
    params.reject! { |_, v| v.blank? }
    @product           = Product.find(params[:id])
    @root_category     = Rails.cache.fetch("admin-product-edit-root_category-#{@product.id}-#{@product.updated_at}", expires_in: 24.hours) do
      ProductType.find_by(name: @product.prototype.try(:name))
    end

    @selected = params[:selected] || []
    if @selected.present?
      @selected = @selected.split(',')
      @selected = @selected.map(&:to_i)
    end

    @variants = filtered_variants(@product)
    form_info
    load_pre_sale_form_info
  end

  def destroy
    @product = Product.find(params[:id])
    @product.destroy
    flash[:notice] = 'Successfully destroyed product.'
    redirect_to admin_merchandise_unidentified_products_url
  end

  def update
    @product = Product.find(params[:id])
    @product.uncache_image_keys

    # Remove new_images from images_attributes to avoid errors on save
    params['product']['images_attributes'].extract!(:new_images) if params['product']['images_attributes'].present?
    @product.variants_attributes = variants_params
    @product.images_attributes   = images_params
    product_parameters = allowed_params
    product_parameters[:tax_code] = product_parameters[:tax_code].blank? ? nil : product_parameters[:tax_code].strip
    product_parameters[:limited_time_offer_data] = {} unless product_parameters[:limited_time_offer]&.to_bool
    @product.attributes = product_parameters

    @product.annotation_list = begin
      allowed_params[:annotation_list]
    rescue StandardError
      ''
    end

    @product.additional_upcs = String(allowed_params[:additional_upcs]).split(' ')

    if @product.save && activate_product?(params) # errors for the activate
      redirect_to admin_merchandise_product_url(@product)
    else
      form_info
      @varietal = ProductType.find_by(name: @product.prototype.try(:name))
      @variants = filtered_variants(@product)

      load_pre_sale_form_info

      render action: :edit
    end
  end

  def create_pre_sale
    @product = Product.find(params[:id])
    c_pre_sale = ::PreSales::Create.new(pre_sale_params.to_h).call
    @pre_sale = c_pre_sale.pre_sale

    if c_pre_sale.success?
      ::PreSales::UpdateVariants.new(@pre_sale).call
      return redirect_to action: :edit, id: @pre_sale.product_id
    end

    @product_order_limit = @pre_sale.product_order_limit

    @state_product_order_limits    = build_state_product_order_limits(pre_sale_params)
    @supplier_product_order_limits = build_supplier_product_order_limits(pre_sale_params)

    @variants = filtered_variants(@product)
    form_info

    params[:active_tab] = 'pre-sales'

    flash[:error] = 'The Pre sale could not be created'
    render action: :edit
  end

  def change_variants_product
    @product = Product.find(params[:product_id])
    @variants = Variant.where('id in (?)', params[:variant_ids])
  end

  def save_change_variants_product
    return render status: '500', json: { text: 'Something went wrong' } if !params[:old_product] || !params[:new_product] || params[:variant_ids].empty?

    old_product = Product.find(params[:old_product])
    new_product = Product.find(params[:new_product])
    @variants = Variant.where('id in (?)', params[:variant_ids].split(','))

    return render status: '500', json: { text: 'Something went wrong' } if !old_product || !new_product || @variants.empty?

    new_product_upcs = new_product.additional_upcs || []
    new_product_upcs << new_product.upc if new_product.upc
    @variants.each do |variant|
      upc = variant.original_upc
      variant.product_id = new_product.id
      variant.save
      next unless upc

      # add the upc to additional_upcs if it is not already there
      unless new_product_upcs.include?(upc)
        new_product.additional_upcs << upc
        new_product.save
      end

      variants_with_upc = Variant.where(product_id: old_product.id, original_upc: upc).count
      # if there is no other variant with that original_upc we remove it from the product's additional_upcs
      if variants_with_upc.zero? && old_product.additional_upcs.present? && old_product.additional_upcs.include?(upc)
        old_product.additional_upcs.delete(upc)
        old_product.save
      end
    end
    render status: '200', json: { success: true }
  end

  def subtypes # TODO: nuke
    ## the proto_id can be root category or prototype id
    ptype = ProductType.find_by(id: params[:ptype_id]) if params[:ptype_id]
    ptype ||= ProductType.find_by(id: params[:root_ptype_id]) if params[:root_ptype_id]
    ptype ||= ProductType.find_by(name: Prototype.find_by(id: params[:proto_id]).try(:name)) if params[:proto_id]
    json = ptype ? ptype.children.map { |i| [i.id, i.name] } << [ptype.id, ptype.name] : []
    render json: json
  end

  def add_properties
    category   = ProductType.find(params[:id]).root
    prototype  = Prototype.find_by(name: category.name)
    @properties = prototype.properties
    all_properties = Property.all

    @properties_hash = all_properties.each_with_object(active: [], inactive: [], types: []) do |property, h|
      if @properties.detect { |p| p.id == property.id }
        h[:active] << property.id
      else
        h[:inactive] << property.id
      end
      h
    end

    ptype = ProductType.find_by(name: prototype.name)

    @properties_hash[:types] = ptype ? ptype.children.map { |t| [t.id, t.name] } : []

    respond_to do |format|
      format.html
      format.json { render json: @properties_hash.to_json }
    end
  end

  def activate
    ProductActivationWorker.perform_async(params[:id])
    redirect_to admin_merchandise_product_url
  end

  def add_variant
    @product = Product.find(params[:id])
    variants_params = params[:variant]

    @variant = if variants_params[:variant_id].present?
                 Variant.find(variants_params[:variant_id])
               else
                 @product.variants.new
               end
    @variant.sku           = variants_params[:sku]
    @variant.supplier_id   = variants_params[:supplier_id]
    @variant.price         = variants_params[:price]
    @variant.sale_price    = variants_params[:sale_price]
    @variant.case_eligible = variants_params.fetch(:case_eligible, false)
    @variant.protected     = variants_params.fetch(:protected, false)
    @variant.name          = @product.name
    @variant.two_for_one   = variants_params[:two_for_one]

    if @variant.self_active? && variants_params[:deactivate].present?
      @variant.deleted_at = Time.zone.now
    elsif !@variant.self_active? && variants_params[:deactivate].blank?
      @variant.deleted_at = nil
    end

    respond_to do |format|
      if @variant.save
        if @variant.inventory
          new_count = @variant.inventory.count_on_hand + variants_params[:qty_to_add].to_i
          new_count = 0 if new_count.negative?
          @variant.inventory.update_attribute(:count_on_hand, new_count) if new_count >= 0
          @variant.touch
        end

        if request.referer.include? 'admin/merchandise/product_size_grouping'
          format.html { redirect_to edit_admin_merchandise_product_size_grouping_path(@product.product_size_grouping, tab: 'sizes', size: @product.id) }
        else
          @variants = filtered_variants(@product)
          format.js
        end
      else
        Rails.logger.error @variant.errors.full_messages
        format.json { render json: @variant.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def toggle_variant_state
    @product = Product.find(params[:id])
    @variant = Variant.find(params[:variant_id])
    if @variant.deleted_at.nil?
      @variant.update_attribute(:deleted_at, Time.zone.now)
    else
      @variant.update_attribute(:deleted_at, nil)
    end
    redirect_to action: :show
  end

  def update_variants
    @product = Product.find(params[:id])
    previous_selected = params[:product][:previous_selected].split(' ') if params[:product][:previous_selected].present?
    selected = params[:selected] if params[:selected].present?
    all_selected = (previous_selected || []) + (selected || [])
    if params[:commit] == 'Split All Pages'
      variants = filtered_variants(@product, search_params, true).select('id')
      all_selected = variants.map(&:id)
    end
    case params[:commit]
    when 'Save Changes'
      errors = []
      threads = []
      variant_attributes = product_params[:variants_attributes].to_h.map { |_, variants_params_array| variants_params_array }
      variant_attributes.each_slice(100).to_a.each do |variants_params_array|
        threads << Thread.new do
          variants_params_array.each do |variants_params|
            @variant = Variant.find(variants_params[:id])
            @variant.sku           = variants_params[:sku]
            @variant.price         = variants_params[:price]
            @variant.sale_price    = variants_params[:sale_price]
            @variant.case_eligible = variants_params[:case_eligible] == '1'
            @variant.protected     = variants_params[:protected] == '1'
            @variant.tax_exempt    = variants_params[:tax_exempt] == '1'
            @variant.frozen_inventory = variants_params[:frozen_inventory] == '1'
            @variant.two_for_one   = (0.05                                 if variants_params[:two_for_one] == '1')
            @variant.deleted_at    = (@variant.deleted_at || Time.zone.now if variants_params[:deleted] == '1')

            @variant.inventory.update(count_on_hand: @variant.inventory.count_on_hand + variants_params[:qty_to_add].to_i)
            @variant.errors.map { |e| errors << "Variant id (#{@variant.id}): #{e.full_message}" } unless @variant.save
          end
        end
      end
      ActiveSupport::Dependencies.interlock.permit_concurrent_loads { threads.each(&:join) }

      if errors.any?
        params[:active_tab] = 'variants'
        flash[:alert] = errors.join('<br>')
      end
    when 'Split Selected', 'Split All Pages'
      if all_selected.empty?
        flash[:notice] = 'No variants selected for split off'
      else
        # TODO: create a new product size grouping too (or this new product will get merged back automatically by rake tasks)
        result = split_variants_into_new_product(@product, all_selected)
        if result[:errors].empty?
          @product = Product.find result[:new_product][:id]
          flash[:notice] = 'Successfully split off new product'
        else
          flash[:alert] = result[:errors].join(', ')
        end
      end
    when 'Move Selected to Other Product'
      if all_selected.empty?
        flash[:notice] = 'No variants selected for split off'
      else
        variant_ids = all_selected
        redirect_to admin_merchandise_product_change_variants_product_path(@product, variant_ids: variant_ids)
        return
      end
    end
    redirect_to action: :edit, id: @product.permalink, active_tab: params[:active_tab]
  end

  def find_products_with_upc
    @product = Product.find(params[:id])
    render json: @product.get_other_products_with_upc(params[:upc])
  end

  def add_additional_upc
    @product = Product.find(params[:id])
    upc = params[:upc]
    products_to_remove_upc = params[:products_to_remove]
    products_to_remove_upc.each do |p_id|
      product = Product.find p_id
      remove_additional_upc_from_product(product, upc)
    end
    @product.additional_upcs << upc
    if @product.save
      render json: { success: true }
    else
      render json: { success: false }
    end
  end

  def remove_additional_upc
    @product = Product.find params[:id].to_i
    upc = params[:upc]
    products_to_remove_upc = params[:products_to_remove]
    results = []
    errors = []
    product_ids_to_remove_variants = []
    products_to_remove_upc.each do |p_id|
      product = Product.find p_id.to_i
      errors += remove_additional_upc_from_product(product, upc)
      product_ids_to_remove_variants << p_id
    end
    errors += remove_additional_upc_from_product(@product, upc)
    product_ids_to_remove_variants << @product.id
    results += split_product_variants_with_upc(product_ids_to_remove_variants, upc, @product)
    render json: { success: true, results: results, errors: errors }
  end

  def reindex
    @product = Product.find(params[:id])
    @product.reindex_async
    @product.variants.find_each(&:reindex_async)

    flash[:notice] = "Reindexing #{@product.name}. This should be done shortly."
    redirect_to action: :show
  end

  def regroup
    @product = Product.find(params[:id])
    ProductSizeGrouping.regroup_product(@product)

    flash[:notice] = "Removed '#{@product.name}' from grouping and assigned to new grouping named: '#{@product.product_size_grouping&.name}.'  NOTE: New grouping doesn't have any metadata, please update accordingly!"
    redirect_to action: :show
  end

  private

  def allowed_params
    params.require(:product).permit(:allows_back_order, :default_search_hidden, :name, :description, :product_subtype_id, :prototype_id,
                                    :sku, :permalink, :set_keywords, :tax_code, :pre_engraved_message, :master, :limited_time_offer,
                                    :upc, :upc_ext, :additional_upcs, :item_volume, :tax_category_id, :volume_value,
                                    :volume_unit, :container_count, :container_type, :max_quantity_per_order, :annotation_list,
                                    limited_time_offer_data: [:delivery_expectation, :maximum_delivery_expectation, :global_limit, { states: [] }],
                                    product_properties_attributes: %i[property_id description id],
                                    product_size_grouping_attributes: %i[product_type_id brand_id meta_description meta_keywords description tag_list name set_keywords])
  end

  def product_params
    params.require(:product).permit(:allows_back_order, :default_search_hidden, :name, :description, :product_subtype_id, :prototype_id,
                                    :sku, :permalink, :set_keywords, :master, :limited_time_offer,
                                    :upc, :additional_upcs, :item_volume, :tax_category_id, :volume_value,
                                    :volume_unit, :container_count, :container_type, :max_quantity_per_order, :annotation_list,
                                    limited_time_offer_data: [:delivery_expectation, :maximum_delivery_expectation, :global_limit, { states: [] }],
                                    variants_attributes: %i[deleted protected case_eligible tax_exempt frozen_inventory price sale_price original_price sku qty_to_add original_upc id two_for_one],
                                    images_attributes: %i[_destroy photo photo_from_link id],
                                    product_properties_attributes: %i[property_id description id])
  end

  def search_params
    params.require(:product).permit(:supplier_name, :variant_name, :sku, :original_upc, :price_min, :price_max, :variant_name_exclude, :business_id)
  end

  def variants_params
    ::NestedAttributesParameters.new(product_params[:variants_attributes] || {}).except(:new_variants)
  end

  def images_params
    ::NestedAttributesParameters.new(product_params[:images_attributes] || {})
  end

  def product_groupings
    Rails.cache.fetch('admin_fuzzy_groupings', expires_in: 5.days) do
      groupings = []
      Brand.find_each { |brand| groupings << Regexp.new(brand.name, true) }
      groupings
    end
  end

  def remove_additional_upc_from_product(product, upc)
    errors = []
    if product&.additional_upcs&.index(upc)
      product.additional_upcs.delete_at(product.additional_upcs.index(upc))
      errors = product.errors.full_messages unless product.save
    end
    errors
  end

  def split_product_variants_with_upc(product_ids, upc, base_product)
    # TECH-4214 - we need to search the upc on the original_upc and on the sku columns.
    variants = Variant.where(product_id: product_ids, original_upc: upc).or(Variant.where(product_id: product_ids, sku: upc))
    variant_ids = variants.map(&:id)
    results = []
    unless variant_ids.empty?
      result = split_variants_into_new_product(base_product, variant_ids, upc)
      results << result
    end
    results
  end

  def split_variants_into_new_product(product, variant_ids, upc = nil)
    new_product = product.simple_duplicate
    new_product.name = variant_ids.reduce(nil) { |acc, variant_id| acc ||= Variant.find(variant_id).original_name.presence }
    new_product.name ||= 'No Product Name'
    # if we receive a upc and there is no product using that upc we set it on the new product.
    unless upc.nil?
      upc_product = Product.find_by(upc: upc)
      new_product.upc = upc if upc_product.nil?
    end
    errors = []
    if new_product.save
      variant_ids.each { |variant_id| Variant.find(variant_id).update(product_id: new_product.id) }
      product.reindex_async
    else
      errors << "Sorry, error splitting off variants from product #{product.name}. #{new_product.errors.full_messages.join(' , ')}"
    end
    { original_product: { id: product.id, name: product.name }, new_product: { id: new_product.id, name: new_product.name }, errors: errors }
  end

  def image_groups
    @image_groups ||= ImageGroup.where(product_id: @product).map { |i| [i.name, i.id] }
  end

  def form_info
    @prototypes          = Prototype.all.collect { |pt| [pt.name, pt.id] }
    @all_properties      = Property.all
    @select_tax_category = TaxCategory.all.collect { |sc| [sc.name, sc.id] }
  end

  def load_pre_sale_form_info
    @pre_sale = PreSale.find_or_initialize_by(product_id: @product.id, status: 'active')
    @product_order_limit = @pre_sale.persisted? ? @pre_sale.product_order_limit : ProductOrderLimit.new

    @state_product_order_limits       = @pre_sale.persisted? ? @product_order_limit.state_product_order_limits : []
    @supplier_product_order_limits    = @pre_sale.persisted? ? @product_order_limit.supplier_product_order_limits : []
  end

  def product_type_list
    cache_string = "/admin/merchandise/products/product_type_list-#{ProductType.count}"

    Rails.cache.fetch(cache_string, expires_in: 24.hours) do
      types = ProductType.active.roots
      types = types.map(&:self_and_descendants).flatten
      types.map { |pt| [pt.sorted_self_and_ancestors.map(&:name).join(' | '), pt.id] }
    end
  end

  def sort_column
    Product.column_names.include?(params[:sort]) ? params[:sort] : 'name'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end

  def activate_product?(params = {})
    if params[:commit] == 'Update and Activate' && !@product.active? # if update and activate button
      @product.activate
    else
      true # default to true
    end
  end

  def prevent_browser_caching
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate' # HTTP 1.1.
    response.headers['Pragma'] = 'no-cache' # HTTP 1.0.
    response.headers['Expires'] = '0' # Proxies.
  end

  def filtered_variants(product, params_data = nil, skip_page = false)
    params_data = params if params_data.nil?
    business_id = params_data[:business_id].nil? ? Business::MINIBAR_ID : params_data[:business_id]
    scope = product.variants.joins(:supplier)
    scope = scope.includes(:supplier, :inventory)
    scope = scope.where('suppliers.name         ilike ?', "%#{params_data[:supplier_name]}%") if params_data[:supplier_name].present?
    scope = scope.where('variants.original_name ilike ?', "%#{params_data[:variant_name]}%")  if params_data[:variant_name].present?
    scope = scope.where('variants.sku            like ?', "%#{params_data[:sku]}%")           if params_data[:sku].present?
    scope = scope.where('variants.original_upc   like ?', "%#{params_data[:original_upc]}%")  if params_data[:original_upc].present?
    scope = scope.where('variants.price          >= ?',   params_data[:price_min])            if params_data[:price_min].present?
    scope = scope.where('variants.price          <= ?',   params_data[:price_max])            if params_data[:price_max].present?
    scope = scope.where(supplier_id: BusinessSupplier.where(business_id: business_id.to_i).map(&:supplier_id)) unless Business.default_business?(business_id.to_i)

    scope = scope.where.not('variants.original_name ilike ?', "%#{params_data[:variant_name_exclude]}%") if params_data[:variant_name_exclude].present?
    scope = scope.order('variants.deleted_at DESC, suppliers.name ASC')
    return scope if skip_page

    scope.page(params_data[:variants_page]).per(50)
  end
end
