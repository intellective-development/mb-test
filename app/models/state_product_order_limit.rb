# == Schema Information
#
# Table name: state_product_order_limits
#
#  id                     :integer          not null, primary key
#  product_order_limit_id :integer          not null
#  state_id               :integer          not null
#  order_limit            :integer          not null
#  current_order_qty      :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_state_order_limits_on_product_order_limit_and_state  (product_order_limit_id,state_id) UNIQUE
#  index_state_product_order_limits_on_state_id               (state_id)
#
# Foreign Keys
#
#  fk_rails_...  (product_order_limit_id => product_order_limits.id)
#  fk_rails_...  (state_id => states.id)
#
class StateProductOrderLimit < ActiveRecord::Base
  belongs_to :product_order_limit
  belongs_to :state

  validates :product_order_limit_id, :state_id, :order_limit, presence: true

  scope :active, lambda {
    joins(product_order_limit: :pre_sales)
      .where(pre_sales: { status: 'active' })
      .where('order_limit IS NULL OR order_limit >= 0')
  }

  has_paper_trail ignore: %i[created_at updated_at]

  after_update -> { PreSale.expire_cache(product_order_limit.product_id) }
end
