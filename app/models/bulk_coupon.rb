# == Schema Information
#
# Table name: bulk_coupons
#
#  id            :integer          not null, primary key
#  code_prefix   :string
#  free_delivery :boolean          default(FALSE)
#  free_shipping :boolean          default(FALSE)
#  domain_name   :string
#  coupon_type   :string
#  quantity      :integer
#  description   :string
#  amount        :string
#  percent       :string
#  starts_at     :string
#  expires_at    :string
#  user_id       :integer
#  storefront_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_bulk_coupons_on_storefront_id  (storefront_id)
#  index_bulk_coupons_on_user_id        (user_id)
#
class BulkCoupon < ActiveRecord::Base
  belongs_to :storefront, optional: false
  belongs_to :user, optional: false
  has_many :coupons

  validates :starts_at, :expires_at, :quantity, :coupon_type, :description, presence: true
  validates_associated :coupons

  accepts_nested_attributes_for :coupons

  COUPONS_CSV_COLUMNS = %w[id type code amount minimum_value percent minimum_units description combine starts_at expires_at created_at updated_at maximum_value sellable_type generated active quota single_use nth_order free_delivery restrict_items reporting_type_id doorkeeper_application_ids skip_fraud_check order_item_id recipient_email send_date delivered supplier_type storefront_id engraving_percent free_service_fee nth_order_item free_product_id free_product_id_nth_count exclude_pre_sale sellable_restriction_excludes domain_name free_shipping].freeze

  def coupons_csv
    @coupons_csv ||= CSV.generate(headers: true) do |csv|
      csv << COUPONS_CSV_COLUMNS

      coupons.each do |coupon|
        csv << coupon.attributes.values_at(*COUPONS_CSV_COLUMNS)
      end
    end
  end
end
