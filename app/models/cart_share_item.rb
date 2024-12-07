# == Schema Information
#
# Table name: cart_share_items
#
#  id            :integer          not null, primary key
#  cart_share_id :integer          not null
#  variant_id    :integer          not null
#  quantity      :integer          default(1)
#  created_at    :datetime
#  updated_at    :datetime
#
# Indexes
#
#  index_cart_share_items_on_cart_share_id  (cart_share_id)
#  index_cart_share_items_on_variant_id     (variant_id)
#

class CartShareItem < ActiveRecord::Base
  belongs_to :cart_share
  belongs_to :variant
  has_one :product_grouping_variant_store_view, through: :variant

  delegate :product_id, to: :variant, allow_nil: true

  validates :cart_share, presence: true
  validates :variant, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0, less_than: 999 }

  # TODO: LD: this should really be merging an "available" scope from product_grouping_variant_store_view,
  # Right now, that scope is built into the view, so doing an inner join like this will prevent
  # items from loading whose variants aren't shoppable.
  #
  # TODO: LD: consider removing this anyways when we pull the where clause out of the pgvsv, as ideally
  # we wouldn't be doing this check in the only place we're calling this scope.
  scope :available, -> { joins(:product_grouping_variant_store_view) }

  #-----------------------------------------------------
  # Class methods
  #-----------------------------------------------------

  def self.build_from_order_item(order_item) # build or create?
    attrs = order_item.attributes.symbolize_keys.slice(:variant_id, :quantity)
    CartShareItem.new(variant_id: order_item.variant_id, quantity: order_item.quantity)
  end
end
