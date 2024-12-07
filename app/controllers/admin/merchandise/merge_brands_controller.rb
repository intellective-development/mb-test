class Admin::Merchandise::MergeBrandsController < Admin::BaseController
  layout 'admin'
  protect_from_forgery except: :update, if: :json_request?

  def index
    @all = true
    @source_brand = Brand.find_by(id: params[:source_id])
    @destination_brand = Brand.find_by(id: params[:destination_id])

    # generate a url for linking to merge tool with source and destination swapped
    @swap_url = admin_merchandise_merge_brands_path
    hash = {}
    hash[:source_id] = @destination_brand ? params[:destination_id] : nil
    hash[:destination_id] = @source_brand ? params[:source_id] : nil
    @swap_url += "?#{hash.compact.to_query}"
  end

  def show
    @brand = Brand.find_by(id: params[:id])
    render layout: nil
  end

  def update
    BrandMergeWorker.perform_async(params['source'], params['target'], merge_params(true), current_user.id)
  rescue MergeError::NoPossibleMergeError => e
    response = {
      text: 'NoPossibleMerge',
      id: e.unknown_id,
      side: e.destination ? 'Destination' : 'Source'
    }
    render status: '500', json: response
  rescue RuntimeError => e
    notify_sentry_and_log(e, e.message, tags: { source_id: @source_brand&.id, destination_id: @destination_brand&.id })
    render status: '500', json: { text: 'Something went wrong' }
  else
    render status: '200', json: { success: true }
  end

  def brand_search
    filters = {}
    filters[:state] = { not: ['merged'] }

    brands =
      Brand.search(
        params[:term].to_s,
        where: filters,
        limit: 50
      )
    render json: get_brands_json(brands)
  end

  private

  def json_request?
    request.format.json?
  end

  def get_brands_json(brands)
    searchkick_brands_ids = brands.map(&:id)
    valid_brands = Brand.where(id: searchkick_brands_ids)
    brands_json = ConsumerAPIV2::Entities::SearchBrand.represent(valid_brands).to_json
    brands_json.presence || []
  end

  def merge_params(skip_validation = false)
    params_hash = {
      replace_name: params[:replace_name].to_bool,
      replace_description: params[:replace_description].to_bool
    }
    params_hash[:validate_mergeable] = false if skip_validation
    params_hash
  end
end
