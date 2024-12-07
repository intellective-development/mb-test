class Admin::Generic::BulkCouponsController < Admin::Generic::BaseController
  include Sellables
  before_action :add_to_all, only: :create
  before_action :check_user
  before_action :set_default_coupon_params, only: %i[new create]

  def index
    @bulk_coupons = BulkCoupon.all.order(id: :desc)
  end

  def new
    @bulk_coupon = BulkCoupon.new
  end

  def create
    @bulk_coupon = BulkCoupon.new(bulk_params)
    @bulk_coupon.user = current_user

    if @bulk_coupon.validate && build_coupons && @bulk_coupon.save
      flash.notice = "Successfully created #{@bulk_coupon.reload.coupons.count} coupons."
      redirect_to admin_generic_bulk_coupons_path
    else
      render :new
    end
  end

  def csv
    @bulk_coupon = BulkCoupon.find(params[:id])

    send_data @bulk_coupon.coupons_csv, filename: "bulk_coupons_#{Date.today.strftime('%m/%d/%Y')}.csv"
  end

  private

  def check_user
    redirect_to admin_path unless current_user.super_admin?
  end

  def generate_code(prefix)
    Coupons::CouponCodeService.new.generate_code(prefix)
  end

  def add_to_all
    params[:coupon][:sellable_ids] = nil if params[:coupon][:sellable_type] == 'All'
  end

  def set_default_coupon_params
    params[:coupon] ||= {}
    params[:coupon].reverse_merge!(
      {
        combine: 'true',
        free_delivery: 'false',
        free_shipping: 'false',
        free_service_fee: 'false',
        single_use: 'false',
        skip_fraud_check: 'false', # we are forcing this to be true on the create_coupons
        restrict_items: 'false',
        exclude_pre_sale: 'false',
        sellable_restriction_excludes: 'false'
      }
    )
  end

  def build_coupons
    @bulk_coupon.quantity.to_i.times do
      coupon = @bulk_coupon.coupons.build(coupon_params.merge(coupon_params_from_bulk))
      coupon.assign_attributes(
        code: generate_code(@bulk_coupon.code_prefix),
        type: bulk_params[:coupon_type],
        engraving_percent: params[:coupon][:engraving_percent].presence || 0,
        minimum_value: params[:coupon][:minimum_value].presence || 0,
        quota: params[:coupon][:quota].presence || nil,
        skip_fraud_check: true,
        reporting_type_id: 1
      )
    end
  end

  def bulk_params
    params.require(:bulk_coupon).permit(
      :storefront_id, :quantity, :coupon_type, :code_prefix, :description, :amount,
      :percent, :starts_at, :expires_at, :domain_name
    )
  end

  def coupon_params
    params.require(:coupon).permit(
      :combine, :description, :free_delivery, :free_shipping, :free_service_fee, :single_use, :skip_fraud_check,
      :quota, :restrict_items, :exclude_pre_sale, :sellable_restriction_excludes, :sellable_type, :sellable_id, :starts_at
    )
  end

  def coupon_params_from_bulk
    params.require(:bulk_coupon).permit(:storefront_id, :description, :amount, :percent, :starts_at, :expires_at, :domain_name)
  end
end
