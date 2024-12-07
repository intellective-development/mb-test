class Admin::Merchandise::MergeGroupingsController < Admin::BaseController
  layout 'admin'

  def index
    @out_of_stock = params.fetch(:out_of_stock, false)
    @pending      = params.fetch(:pending, false)

    if params[:supplier_id].present? # load in list of product groupings
      @all = false
      @supplier_id = params[:supplier_id]
      @supplier = Supplier.find(@supplier_id)
      @destroy_product_grouping_list = get_product_groupings_json(product_grouping_list)
    else
      @all = true
      @destroy_product_grouping_list = get_product_groupings_json([])
    end

    @source_grouping = ProductSizeGrouping.active.find_by(id: params[:source_grouping_id])
    @destination_grouping = ProductSizeGrouping.active.find_by(id: params[:destination_grouping_id])

    # generate a url for linking to merge tool with source and destination swapped
    @swap_url = admin_merchandise_merge_groupings_path
    hash = {}
    hash[:source_grouping_id] = @destination_grouping ? params[:destination_grouping_id] : nil
    hash[:destination_grouping_id] = @source_grouping ? params[:source_grouping_id] : nil
    @swap_url += "?#{hash.compact.to_query}"
  end

  def show
    @product_grouping = begin
      ProductSizeGrouping.find(params[:id])
    rescue StandardError
      nil
    end
    render layout: nil
  end

  def update
    merge_service = ProductGroupingMergeService.new(params['source'], params['target'], merge_params, current_user.id)
    merge_service.validate_product_groupings_mergeable
    ProductGroupingMergeWorker.perform_async(params['source'], params['target'], merge_params(true), current_user.id)
  rescue MergeError::ProductsNeedMergingError => e
    products = e.merge_list.map do |pair|
      {
        source_name: pair[:source][:name],
        dest_name: pair[:destination][:name],
        merge_link: admin_merchandise_merge_index_path(source_id: pair[:source][:id], destination_id: pair[:destination][:id]),
        volume_details: pair[:volume] || '(No Volume)'
      }
    end
    response = { text: 'ProductsNeedMergingError', products: products }
    render status: '500', json: response
  rescue MergeError::NoPossibleMergeError => e
    response = {
      text: 'NoPossibleMerge',
      id: e.unknown_id,
      side: e.destination ? 'Destination' : 'Source'
    }
    render status: '500', json: response
  else
    render status: '200', json: { success: true }
  end

  def product_grouping_search
    product_groupings = ProductGroupingSearch::MergeTool.new(params).search

    render json: get_product_groupings_json(product_groupings)
  end

  private

  def product_grouping_list
    ProductGroupingSearch::MergeTool.new(params.merge(limit: 500)).search
  end

  def get_product_groupings_json(product_groupings)
    searchkick_grouping_ids = product_groupings.map(&:id)
    valid_groupings = ProductSizeGrouping.where(id: searchkick_grouping_ids).order(master: :desc)
    product_groupings_json = ConsumerAPIV2::Entities::SearchGrouping.represent(valid_groupings).to_json
    product_groupings_json.presence || []
  end

  def merge_params(skip_validation = false)
    params_hash = {
      replace_name: params[:replace_name].to_bool,
      replace_description: params[:replace_description].to_bool,
      replace_image: params[:replace_image].to_bool,
      replace_category: params[:replace_category].to_bool,
      activate: params[:activate].to_bool,
      merge_properties: params[:merge_properties].to_bool
    }
    params_hash[:validate_mergeable] = false if skip_validation
    params_hash
  end
end
