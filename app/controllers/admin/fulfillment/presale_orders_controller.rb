class Admin::Fulfillment::PresaleOrdersController < Admin::Fulfillment::BaseController
  helper_method :sort_column, :sort_direction
  SEARCHABLE_FIELDS = [{ first_name: :word_start }, { last_name: :word_start }, :email, { number: :word_middle }, { gift_recipient: :word_start }, { street_address: :text_middle }, { company_name: :word_start }].freeze
  INCLUDES = [:gift_detail, :comments, :address, :pickup_detail, :shipping_method, :shipment_amount, :supplier, :metadata, { order: [:payment_profile, { user: [:account] }], order_items: [variant: [:product, { product_size_grouping: [:hierarchy_type] }]] }].freeze

  def index
    @grouped_shipments = paginated_filtered_shipments
    @shipments_count = @grouped_shipments.total_count
    @canceled_shipments_count = canceled_shipments.total_count
    @cancelation_rate = @shipments_count.zero? ? 0 : ((@canceled_shipments_count.to_f / @shipments_count) * 100).round(2)
  end

  protected

  def sort_column
    params[:sort] || 'order_completed_at'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'desc'
  end

  def permitted_filter_params
    params.permit(:supplier_id, :product_id, :brand_id, :start_date, :end_date)
  end

  private

  def canceled_shipments
    new_search_args = search_args.deep_merge(where: { state: 'canceled' })

    Shipment.search(search_query, new_search_args)
  end

  def paginated_filtered_shipments
    new_search_args = search_args.merge(per_page: 25, page: pagination_page)

    Shipment.search(search_query, new_search_args)
  end

  def search_args
    {
      fields: searchable_fields,
      includes: included_fields,
      where: search_filters,
      order: [{ _score: :desc }, { completed_at: { order: :desc } }],
      misspellings: false
    }
  end

  def search_query
    params[:query] || '*'
  end

  def searchable_fields
    @searchable_fields ||= SEARCHABLE_FIELDS
  end

  def included_fields
    @included_fields ||= INCLUDES
  end

  def search_filters
    filters = {}

    filters[:customer_placement] = :pre_sale
    filters[:supplier_id] = permitted_filter_params[:supplier_id] if params[:supplier_id].present?
    filters[:product_id] = permitted_filter_params[:product_id] if params[:product_id].present?
    filters[:brand_id] = permitted_filter_params[:brand_id] if params[:brand_id].present?
    filters[:created_at] = {}
    filters[:created_at][:gte] = Date.parse(permitted_filter_params[:start_date]) if params[:start_date].present?
    filters[:created_at][:lte] = Date.parse(permitted_filter_params[:end_date]) if params[:end_date].present?

    filters
  end
end
