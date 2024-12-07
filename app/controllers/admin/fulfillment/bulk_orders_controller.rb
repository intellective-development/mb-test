class Admin::Fulfillment::BulkOrdersController < Admin::BaseController
  before_action :find_bulk_order, only: %i[show edit update invoice apply_gift_card finalize refresh]
  before_action :require_active_bulk_order, only: %i[update apply_gift_card finalize refresh]

  respond_to :html

  def index
    # build searchkick query
    filters = {}
    filters[:name] = { like: "%#{permitted_filter_params[:name].downcase}%" } if permitted_filter_params[:name].present?
    filters[:storefront] = permitted_filter_params[:storefront_id] if permitted_filter_params[:storefront_id].present?

    filters[:created_at] = {}
    filters[:created_at][:gte] = Time.parse(permitted_filter_params[:date_range_start]) if permitted_filter_params[:date_range_start].present?
    filters[:created_at][:lte] = Time.parse(permitted_filter_params[:date_range_end]) if permitted_filter_params[:date_range_end].present?

    @bulk_orders = BulkOrder.search(where: filters,
                                    per_page: 25,
                                    page: pagination_page,
                                    order: [{ created_at: { order: :desc } }],
                                    includes: [:storefront])

    respond_with @bulk_orders
  end

  def new
    @bulk_order = BulkOrder.new
    respond_with @bulk_order
  end

  def show
    flash[:notice] = 'This bulk order is still in progress. Please wait until it is completed.' if @bulk_order.in_progress?
  end

  # no logic on edit
  # def edit; end

  # no logic on invoice
  # def invoice; end

  def create
    @bulk_order = BulkOrder.new(permitted_params)
    @user = build_user(@bulk_order)

    if @user.valid? && @bulk_order.save
      redirect_to admin_fulfillment_bulk_orders_path
    else
      flash[:alert] = 'Bulk order could not be created.'
      render :new
    end
  end

  def update
    @user = build_user(@bulk_order)
    if @user.valid? && @bulk_order.update(permitted_params)
      flash[:notice] = 'Bulk order is processing. This order will be finalized in the background.'

      @bulk_order.in_progress!
      redirect_to admin_fulfillment_bulk_order_path(@bulk_order)
    else
      flash[:alert] = 'Bulk order could not be updated.'
      render :edit
    end
  end

  def apply_gift_card
    errors = []

    @bulk_order.orders.each do |order|
      next if order.coupon_code.present? && order.coupon_code == permitted_gift_cart_params[:coupon_code]

      Coupons::DecreasingBalance::AddToOrder.new(order: order, coupon_code: permitted_gift_cart_params[:coupon_code]).call
    rescue GiftCardException::AlreadyCoveredError => e
      errors << 'The order is already covered by coupons/gift cards.'
    rescue GiftCardException::DigitalOrderError => e
      errors << "Gift Cards can't be applied on digital orders"
    rescue GiftCardException::ZeroBalanceError => e
      errors << 'The gift card has 0 balance.'
    rescue GiftCardException::InvalidCodeError => e
      errors << "Gift Card with code '#{permitted_gift_cart_params[:coupon_code].upcase}' not found."
    rescue GiftCardException::OrderAdjustmentError => e
      errors << 'There was an error trying to process the order adjustment'
    rescue RuntimeError => e
      errors << "The gift card '#{permitted_gift_cart_params[:coupon_code].upcase}' is invalid."
    end

    if errors.any?
      flash[:alert] = errors
    else
      flash[:notice] = "Gift Card '#{permitted_gift_cart_params[:coupon_code].upcase}' added to order successfully!"
    end

    @bulk_order.update_attribute(:coupon, Coupon.find_by(code: permitted_gift_cart_params[:coupon_code]))
    redirect_to admin_fulfillment_bulk_order_path(@bulk_order)
  end

  def finalize
    BulkOrder::FinalizeOrdersWorker.perform_async(@bulk_order.id)

    flash[:notice] = 'Bulk order finalizing started. This order will be finalized in the background.'

    @bulk_order.finalizing!
    redirect_to admin_fulfillment_bulk_order_path(@bulk_order)
  end

  def refresh
    @bulk_order.process_order_data
    redirect_to admin_fulfillment_bulk_order_path(@bulk_order)
  end

  private

  def require_active_bulk_order
    return true if @bulk_order.active?

    flash[:alert] = "Action cannot be executed in the current state: #{@bulk_order.status}"
    redirect_to admin_fulfillment_bulk_order_path(@bulk_order)
  end

  def find_bulk_order
    @bulk_order = BulkOrder.find(params[:id])
  rescue StandardError
    redirect_to admin_fulfillment_bulk_orders_path
  end

  def build_user(bulk_order)
    temp_password = SecureRandom.uuid
    user_attributes = {
      account_attributes: {
        password: temp_password,
        password_confirmation: temp_password,
        email: "#{SecureRandom.uuid}@anonymo.us",
        contact_email: bulk_order.billing_email,
        first_name: bulk_order.billing_first_name,
        last_name: bulk_order.billing_last_name,
        storefront_id: bulk_order.storefront_id
      },
      utm_source: 'admin',
      utm_medium: 'admin',
      anonymous: true
    }
    User.new(user_attributes)
  end

  def permitted_params
    params.require(:bulk_order).permit(:name,
                                       :storefront_id,
                                       :storefront_quote_id,
                                       :graphic_engraving,
                                       :line1,
                                       :line2,
                                       :line3,
                                       :line4,
                                       :logo,
                                       :coupon_code,
                                       :delivery_method,
                                       :billing_first_name,
                                       :billing_last_name,
                                       :billing_email,
                                       :billing_company,
                                       :billing_address,
                                       :billing_address_info,
                                       :billing_city,
                                       :billing_state,
                                       :billing_zip,
                                       :billing_phone,
                                       :csv,
                                       supplier_ids: [])
  end

  def permitted_filter_params
    params.permit(:name, :storefront_id, :date_range_start, :date_range_end)
  end

  def permitted_gift_cart_params
    params.permit(:storefront_id, :coupon_code)
  end
end
