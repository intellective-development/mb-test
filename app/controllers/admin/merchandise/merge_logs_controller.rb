class Admin::Merchandise::MergeLogsController < Admin::BaseController
  layout 'admin'

  def index
    @type = params[:type] || 'products'
    if @type == 'brands'
      @merges = BrandMerge.includes(:user, :destination, :source)
                          .order(created_at: :desc)
                          .page(params[:page] || 1)
                          .per(params[:per_page] || 50)
    end
    unless @type == 'brands'
      @merges = ProductMerge.includes(:user, :destination, :source)
                            .order(created_at: :desc)
                            .page(params[:page] || 1)
                            .per(params[:per_page] || 50)
    end
  end

  def update
    merge = BrandMerge.find(params[:id]) if params[:type] == 'brands'
    merge = ProductMerge.find(params[:id]) unless params[:type] == 'brands'
    if merge
      merge.undo
      flash[:notice] = 'Merge Reverted'
    else
      flash[:error] = 'Product Merge not found'
    end
    redirect_to admin_merchandise_merge_logs_path(type: params[:type])
  end
end
