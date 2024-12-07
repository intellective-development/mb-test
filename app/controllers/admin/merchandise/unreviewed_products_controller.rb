class Admin::Merchandise::UnreviewedProductsController < Admin::BaseController
  layout 'admin'

  def index
    params[:page] ||= 1

    @products = Product.inactive
                       .includes(%i[product_type active_variants])
                       .page(page: pagination_page)
                       .per(pagination_rows)
  end
end
