class Admin::Merchandise::UnidentifiedProductsController < Admin::BaseController
  layout 'admin'

  def index
    params[:page] ||= 1

    @products = if params[:inactive].present?
                  Product.inactive_or_pending.order('name ASC')
                else
                  Product.pending.order('name ASC')
                end
    @products = @products.with_stock if params[:all].blank? # unless all is chosen, show only in stock (available?)

    supplier_ids = params[:supplier][:supplier_id].reject(&:empty?).map(&:to_i) if params[:supplier]
    if supplier_ids.present?
      @supplier_list = Supplier.where(id: supplier_ids).pluck(:name).join(',')
      @products = @products.select { |p| (p.variants.pluck(:supplier_id) & supplier_ids).present? }
    end
    @products = @products.page(pagination_page).per(pagination_rows)

    @num_products = @products.count
  end

  def deactivate
    product = Product.find(params[:id])
    product.deactivate
    redirect_to action: :index
  end
end
