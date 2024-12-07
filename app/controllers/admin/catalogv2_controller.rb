class Admin::Catalogv2Controller < Admin::BaseController
  def index
    # TODO: We may want to think about whitelisting parameters here.
    searcher = ProductGroupingSearch::AdminCatalogv2.new(params)
    @product_groupings = searcher.search
    @total_count = @product_groupings.total_count
  end

  def toggle_active
    ProductActivationWorker.perform_async(params[:id])
    redirect_back(fallback_location: admin_catalogv2_index_path)
  end

  def activate_all
    ProductGroupingActivationWorker.perform_async(params[:id])
    redirect_back(fallback_location: admin_catalogv2_index_path)
  end
end
