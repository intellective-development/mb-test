class SupplierVariantSearchService
  def initialize(current_supplier, params)
    @query = params[:query].presence || '*'
    @supplier_ids = if current_supplier.manual_inventory && params[:query].present?
                      [current_supplier.id, Supplier.find_by(name: 'Inventory Template Store')&.id].compact
                    else
                      current_supplier.id
                    end
    @filters = {
      supplier_id: @supplier_ids
    }
    @filters[:in_stock] = params[:in_stock] unless params[:in_stock].nil?
    @filters[:active] = (params[:is_active].presence || true)
    @order = {
      parse_product_sort_column(params[:sort_column]) => parse_product_sort_direction(params[:sort_direction])
    }
    @current_supplier = current_supplier
  end

  def search(params)
    variants = Variant.search(
      @query,
      fields: [:product_grouping_name],
      where: @filters,
      includes: [
        :inventory,
        :product,
        { product_size_grouping: [:product_type] }
      ],
      order: @order,
      per_page: params[:per_page] || 20,
      page: params[:page] || 1
    )
    [
      variants.reject { |variant| variant.supplier_id != @current_supplier.id && owned_product_ids.include?(variant.product.id) },
      variants.total_count.to_s,
      variants.total_pages.to_s
    ]
  end

  private

  def owned_product_ids
    @owned_product_ids ||= @current_supplier.products.pluck(:id)
  end

  def parse_product_sort_column(sort)
    case sort
    when 'price'
      'price'
    when 'inventory'
      'inventory'
    else
      'name'
    end
  end

  def parse_product_sort_direction(sort)
    case sort
    when 'desc'
      'desc'
    else
      'asc'
    end
  end
end
