# == Schema Information
#
# Table name: product_order_limits
#
#  id                 :integer          not null, primary key
#  product_id         :integer          not null
#  global_order_limit :integer          not null
#  current_order_qty  :integer          default(0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_product_order_limits_on_product_id  (product_id)
#
# Foreign Keys
#
#  fk_rails_...  (product_id => products.id)
#
class ProductOrderLimit < ActiveRecord::Base
  belongs_to :product

  has_many :supplier_product_order_limits
  has_many :state_product_order_limits
  has_many :pre_sales

  validates :product_id, :global_order_limit, presence: true

  scope :active, -> { joins(:pre_sales).where(pre_sales: { status: 'active' }) }

  has_paper_trail ignore: %i[created_at updated_at]

  after_update -> { PreSale.expire_cache(product.id) }

  def sum_order_items
    OrderItem.joins(:variant, :shipment)
             .merge(Shipment.paid)
             .where(variants: { id: Variant.where(product: product) })
             .where('shipments.created_at >= ?', pre_sales.first&.starts_at)
             .sum(&:quantity)
  end
end
