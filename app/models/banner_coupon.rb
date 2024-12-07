# == Schema Information
#
# Table name: banner_coupons
#
#  id         :integer          not null, primary key
#  key        :string
#  coupon_id  :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_banner_coupons_on_coupon_id  (coupon_id)
#  index_banner_coupons_on_key        (key)
#

class BannerCoupon < ActiveRecord::Base
  INSTALL_APP_KEY = 'install_mobile_app'.freeze

  belongs_to :coupon

  validates :key,            presence: true, uniqueness: { case_sensitive: false }
  validates :coupon_id,      presence: true

  # attr_accessor :code

  def self.admin_grid(params = {})
    BannerCoupon.public_send(Kaminari.config.page_method_name, params[:page] || 1)
                .per(params[:per_page] || 15)
                .order(key: :asc)
  end

  def code
    coupon&.code
  end
end
