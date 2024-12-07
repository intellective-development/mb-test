class Admin::Generic::CouponsController < Admin::Generic::BaseController
  include Sellables
  before_action :add_to_all, only: %i[create update]

  def index
    @coupons = Coupon.admin_grid(grid_params)
  end

  def show
    @coupon = Coupon.find(params[:id])
  end

  def new
    form_info
    @coupon = Coupon.new(combine: true)
  end

  def create
    @coupon = Coupon.new(allowed_params)
    @coupon.type = params[:c_type]
    @coupon.supplier_type = nil if params['coupon']['supplier_type'].blank?
    @coupon.errors.add(:base, 'please select coupon type') if params[:c_type].blank?
    # we do explicit check for storefront to avoid fallback to Minibar when creating coupon from UI
    @coupon.errors.add(:base, 'please select storefront') if @coupon.storefront.nil?

    if @coupon.errors.empty? && @coupon.save
      flash.notice = 'Successfully created coupon.'
      redirect_to admin_generic_coupon_path(@coupon)
    else
      form_info
      render action: 'new'
    end
  end

  def edit
    form_info
    @coupon = Coupon.find(params[:id])
  end

  def update
    @coupon = Coupon.find(params[:id])

    # when nothing is selected in 'Free product' drop-down request misses corresponding param, so its value left unchanged
    # So we manually set it to nil here, to make it empty if previously filled free_product_id is removed
    @coupon.free_product_id = nil
    @coupon.assign_attributes(allowed_params)

    @coupon.doorkeeper_application_ids = [] if params['coupon']['doorkeeper_application_ids'].blank?
    @coupon.supplier_type = nil if params['coupon']['supplier_type'].blank?
    if @coupon.save
      segment_service = Segments::SegmentService.from(@coupon.storefront)
      segment_service.identify_gift_card_recipient(@coupon.recipient_email) if @coupon.gift_card?

      flash.notice = 'Successfully updated coupon.'

      @coupon.expire_rewards! if @coupon.is_a?(CouponReferral) && @coupon.expires_at.past? && params['expire_rewards']

      redirect_to admin_generic_coupon_path(@coupon)
    else
      form_info
      render action: 'edit'
    end
  end

  def destroy
    @coupon = Coupon.find(params[:id])
    @coupon.destroy!
    flash.notice = 'Successfully destroyed coupon.'
    redirect_to admin_generic_coupons_url
  end

  def batch_code_delete
    codes = params[:codes].gsub(/\r\n/, "\n").split("\n")
    codes = codes.map(&:downcase)

    coupons = Coupon.where(code: codes)
    deleted = coupons.delete_all

    redirect_to admin_generic_coupons_url, notice: "#{deleted} coupons deleted."
  end

  def types
    redirect_to edit_admin_generic_coupon_url(params[:id])
  end

  def resend
    @coupon = Coupon.find(params[:id])

    segment_service = Segments::SegmentService.from(@coupon.storefront)
    segment_service.identify_gift_card_recipient(@coupon.recipient_email)
    Coupon::DeliverGiftCardWorker.perform_in(2.minutes, @coupon.id, resend: true)

    flash[:notice] = 'The coupon will be resent in a few seconds.'
    redirect_to admin_generic_coupon_url(params[:id])
  end

  def expire
    @coupon = Coupon.find(params[:id])

    @coupon.expire!

    segment_service = Segments::SegmentService.from(@coupon.storefront)
    segment_service.gift_card_expired(@coupon)
    segment_service.identify_gift_card_recipient(@coupon.recipient_email)

    flash[:notice] = 'The coupon has been expired.'
    redirect_to admin_generic_coupon_url(params[:id])
  end

  private

  def grid_params
    params.permit(:per_page, :page, :search, :include_expired, :hide_generated, :storefront_id)
  end

  def allowed_params
    params.require(:coupon)
          .permit(
            :storefront_id,
            :code,
            :amount,
            :minimum_value,
            :maximum_value,
            :free_delivery,
            :free_service_fee,
            :free_shipping,
            :percent,
            :engraving_percent,
            :description,
            :reporting_type_id,
            :minimum_units,
            :nth_order,
            :sellable_type,
            :sellable_restriction_excludes,
            :combine,
            :starts_at,
            :expires_at,
            :restrict_items,
            :supplier_type,
            :single_use,
            :quota,
            :skip_fraud_check,
            :nth_order_item,
            :free_product_id,
            :free_product_id_nth_count,
            :exclude_pre_sale,
            :domain_name,
            :membership_plan_id,
            doorkeeper_application_ids: [],
            sellable_ids: [],
            price_tiers_attributes: %i[id minimum percent amount _destroy]
          )
  end

  def form_info
    @coupon_types = Coupon::COUPON_TYPES
    @reporting_types = ReportingType.all
  end

  def add_to_all
    params[:coupon][:sellable_ids] = nil if params[:coupon][:sellable_type] == 'All'
  end
end
