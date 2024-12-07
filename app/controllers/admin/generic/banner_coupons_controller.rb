class Admin::Generic::BannerCouponsController < Admin::Generic::BaseController
  def index
    @banner_coupons = BannerCoupon.admin_grid(grid_params)
  end

  def edit
    @banner_coupon = BannerCoupon.find(params[:id])
  end

  def update
    @banner_coupon = BannerCoupon.find(params[:id])
    coupon = Coupon.find_by(code: params[:banner_coupon][:code])
    @banner_coupon.errors.add(:code, 'error. No coupon found with entered code.') unless coupon
    @banner_coupon.coupon = coupon
    @banner_coupon.assign_attributes(allowed_params)

    if @banner_coupon.errors.empty? && @banner_coupon.save
      flash[:notice] = 'Successfully updated info.'

      redirect_to admin_generic_banner_coupons_path(@coupon)
    else
      render action: 'edit'
    end
  end

  private

  def grid_params
    params.permit(:per_page, :page)
  end

  def allowed_params
    params.require(:banner_coupon).permit(:key)
  end
end
