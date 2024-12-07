class Admin::Merchandise::MergeController < Admin::BaseController
  layout 'admin'

  protect_from_forgery except: :update, if: :json_request?

  def index
    @out_of_stock = params.fetch(:out_of_stock, false)
    @pending = params.fetch(:pending, false)

    if params[:supplier_id].present? # load in list of products
      @all = false
      @supplier_id = params[:supplier_id]
      @supplier = Supplier.find(@supplier_id)

      @destroy_product_list = get_products_json(product_list)
    else
      @all = true
      @destroy_product_list = get_products_json([])
    end
    @source_product = Product.active_or_pending.find_by(id: params[:source_id])
    @destination_product = Product.active_or_pending.find_by(id: params[:destination_id])

    # generate a url for linking to merge tool with source and destination swapped
    @swap_url = admin_merchandise_merge_index_path
    hash = {}
    hash[:source_id] = @destination_product ? params[:destination_id] : nil
    hash[:destination_id] = @source_product ? params[:source_id] : nil
    @swap_url += "?#{hash.compact.to_query}"
  end

  def show
    @product = Product.find_by(id: params[:id])
    render layout: nil
  end

  def update
    merge_service = ProductMergeService.new(params['source'], params['target'], merge_params, current_user.id)
    merge_service.validate_products_mergeable
    ProductMergeWorker.perform_async(params['source'], params['target'], merge_params(true), current_user.id)
  rescue MergeError::NoPossibleMergeError => e
    response = {
      text: 'NoPossibleMerge',
      id: e.unknown_id,
      side: e.destination ? 'Destination' : 'Source'
    }
    render status: '500', json: response
  rescue RuntimeError => e
    notify_sentry_and_log(e, e.message, { tags: { source_id: @source_brand&.id, destination_id: @destination_brand&.id } })
    render status: '500', json: { text: 'Something went wrong' }
  else
    render status: '200', json: { success: true }
  end

  def product_search
    filters = {}
    filters[:state] = { not: %w[merged inactive] }
    filters[:variant_count] = { gt: 0 }

    sort = if params[:list] == 'mergee'
             :desc
           else
             :asc
           end

    products =
      Product.search(
        params[:term].to_s,
        where: filters,
        limit: 50,
        order: [{ master: :desc, 'merged_count': sort }]
      )
    render json: get_products_json(products)
  end

  private

  def json_request?
    request.format.json?
  end

  def product_list
    filters = {}
    filters[:suppliers] = [params[:supplier_id]] if params[:supplier_id].present?
    filters[:in_stock_supplier] = [params[:supplier_id]] unless params[:out_of_stock]
    filters[:state] = params[:pending] ? %w[pending flagged] : %w[pending active flagged]
    filters[:variant_count] = { gt: 0 }

    v_count = Product.search('*', load: false, where: filters).total_count

    limit = 500
    offset = v_count > limit ? [*0..v_count - limit].sample : 0

    Product.search('*',
                   includes: [variants: { supplier: [:address] }],
                   where: filters,
                   order: { name: :asc },
                   limit: limit,
                   offset: offset)
  end

  def get_products_json(products)
    searchkick_product_ids = products.map(&:id)
    valid_products = Product.includes(:product_size_grouping, :variants).where(id: searchkick_product_ids).order(master: :desc)
    products_json = ConsumerAPIV2::Entities::SearchProduct.represent(valid_products).to_json
    products_json.presence || []
  end

  def merge_params(skip_validation = false)
    params_hash = {
      replace_name: params[:replace_name].to_bool,
      replace_description: params[:replace_description].to_bool,
      replace_image: params[:replace_image].to_bool,
      replace_category: params[:replace_category].to_bool,
      activate: params[:activate].to_bool,
      remove_upc: params[:remove_upc].to_bool,
      merge_properties: params[:merge_properties].to_bool
    }
    params_hash[:validate_mergeable] = false if skip_validation
    params_hash
  end
end
