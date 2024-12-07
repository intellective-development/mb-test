# == Schema Information
#
# Table name: pre_sales
#
#  id                     :integer          not null, primary key
#  product_id             :integer          not null
#  product_order_limit_id :integer          not null
#  name                   :string           not null
#  price                  :decimal(10, 2)   not null
#  starts_at              :datetime         not null
#  status                 :string           default("active"), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  merchant_sku           :string
#
# Indexes
#
#  index_pre_sales_on_product_id              (product_id)
#  index_pre_sales_on_product_order_limit_id  (product_order_limit_id)
#
# Foreign Keys
#
#  fk_rails_...  (product_id => products.id)
#  fk_rails_...  (product_order_limit_id => product_order_limits.id)
#
class PreSale < ActiveRecord::Base
  belongs_to :product
  belongs_to :product_order_limit

  validates :name, :price, :starts_at, :status, :merchant_sku, presence: true
  validate :check_active_product, if: :product_id_changed?
  validates :product_id, uniqueness: { conditions: -> { active } }

  enum status: { active: 'active', inactive: 'inactive' }

  has_paper_trail ignore: %i[created_at updated_at]

  scope :by_status, ->(status) { where(status: status) }

  scope :by_name, lambda { |name|
    joins(:product)
      .where('pre_sales.name ILIKE :name OR products.name ILIKE :name', name: "%#{name}%")
  }

  after_update -> { PreSale.expire_cache(product.id) }
  after_update :activate_inactive_variants

  def self.find_available(product_id, supplier_id)
    product_order_limit = Rails.cache.fetch(cache_id(product_id, supplier_id),
                                            namespace: cache_namespace(product_id),
                                            expires_in: 24.hours) do
      ProductOrderLimit
        .active
        .where(product_id: product_id)
        .where(pre_sales: { product_id: product_id })
        .joins(supplier_product_order_limits: [{ supplier: :address }])
        .where('(product_order_limits.global_order_limit = 0 or product_order_limits.current_order_qty < product_order_limits.global_order_limit)')
        .where('(supplier_product_order_limits.order_limit = 0 or supplier_product_order_limits.current_order_qty < supplier_product_order_limits.order_limit)')
        .where(supplier_product_order_limits: { supplier_id: supplier_id })
        .where(suppliers: { presale_eligible: true })
        .joins(state_product_order_limits: :state)
        .where('(state_product_order_limits.order_limit = 0 or state_product_order_limits.current_order_qty < state_product_order_limits.order_limit)')
        .where('states.id = addresses.state_id')
        .first
    end
    product_order_limit&.pre_sales&.first
  end

  def self.expire_cache(product_id)
    Rails.cache.delete(namespace: cache_namespace(product_id))
  end

  private

  class << self
    def cache_id(product_id, supplier_id)
      "pre_sale:v2:product_id:#{product_id}:supplier_id:#{supplier_id}"
    end

    def cache_namespace(product_id)
      "pre_sale:v2:product_id:#{product_id}"
    end
  end

  def check_active_product
    errors.add(:product_id, 'Cannot use non active product') unless product.active?
  end

  def activate_inactive_variants
    return unless status_previously_changed?
    return if active?

    Variant.where(product_id: product_id).self_inactive.update_all(deleted_at: nil)
  end
end
