# == Schema Information
#
# Table name: supplier_product_order_limits
#
#  id                     :integer          not null, primary key
#  product_order_limit_id :integer          not null
#  supplier_id            :integer          not null
#  order_limit            :integer          not null
#  current_order_qty      :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  variant_id             :integer
#
# Indexes
#
#  index_supplier_order_limits_on_product_order_limit_and_supplier  (product_order_limit_id,supplier_id) UNIQUE
#  index_supplier_product_order_limits_on_supplier_id               (supplier_id)
#
# Foreign Keys
#
#  fk_rails_...  (product_order_limit_id => product_order_limits.id)
#  fk_rails_...  (supplier_id => suppliers.id)
#
class SupplierProductOrderLimit < ActiveRecord::Base
  belongs_to :product_order_limit
  belongs_to :supplier

  has_one :supplier_address, -> { where(addressable_type: 'Supplier') },
          class_name: 'Address',
          primary_key: :supplier_id,
          foreign_key: :addressable_id,
          inverse_of: false,
          dependent: nil

  validates :product_order_limit_id, :supplier_id, :order_limit, presence: true

  scope :active, lambda {
    joins(product_order_limit: :pre_sales)
      .where(pre_sales: { status: 'active' })
      .where('order_limit IS NULL OR order_limit >= 0')
  }

  has_paper_trail ignore: %i[created_at updated_at]

  after_update -> { PreSale.expire_cache(product_order_limit.product_id) }
end
