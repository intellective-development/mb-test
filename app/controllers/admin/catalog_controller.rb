class Admin::CatalogController < Admin::BaseController
  def index
    # TODO: We may want to think about whitelisting parameters here.
    searcher = ProductGroupingSearch::AdminCatalog.new(params)
    @product_groupings = searcher.search
    @total_count = @product_groupings.total_count
  end

  def toggle_active
    ProductActivationWorker.perform_async(params[:id])
    redirect_to :back
  end

  def activate_all
    ProductGroupingActivationWorker.perform_async(params[:id])
    redirect_to :back
  end
end
