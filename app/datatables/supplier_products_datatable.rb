class SupplierProductsDatatable
  delegate :params, :h, :link_to, :number_to_currency, to: :@view

  def initialize(view, supplier_id)
    @view = view
    @supplier_id = supplier_id
  end

  def as_json(_options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Variant.active.where('supplier_id = ?', @supplier_id).count,
      iTotalDisplayRecords: products.total_count,
      aaData: data
    }
  end

  private

  def data
    products.map do |variant|
      [
        variant.sku,
        variant.product_name,
        variant.item_volume,
        number_to_currency(variant.price),
        variant.inventory.count_on_hand,
        '<a class="edit">Edit</a>',
        '<a class="delete"></a>'
      ]
    end
  end

  def products
    @products ||= fetch_products
  end

  def fetch_products
    products = Variant.includes(%i[inventory product])
                      .active
                      .where('supplier_id = ?', @supplier_id)
                      .order("#{sort_column} #{sort_direction}")

    products = products.page(page).per(per_page)
    products = products.where('lower(name) LIKE lower(:search)', search: "%#{params[:sSearch]}%") if params[:sSearch].present?
    products
  end

  def page
    params[:iDisplayStart].to_i / per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i.positive? ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = ['sku', 'name', 'product.item_volume', 'price', 'inventory.count_on_hand']
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == 'desc' ? 'desc' : 'asc'
  end
end
