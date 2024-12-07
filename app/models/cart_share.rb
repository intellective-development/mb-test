# == Schema Information
#
# Table name: cart_shares
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  share_type :integer          not null
#  address_id :integer
#  coupon_id  :integer
#  created_at :datetime
#  updated_at :datetime
#  order_id   :integer
#

class UnableToCreateShareWithoutAddressError < StandardError; end # this will only be raised for certain types of cart shares
class UnableToCreateShareWithoutItemsError < StandardError; end

class CartShare < ActiveRecord::Base
  belongs_to :user
  belongs_to :coupon
  belongs_to :order # After rails 5 migration, optional: true required
  has_one :address, as: :addressable, dependent: :destroy, autosave: true
  has_many :cart_share_items

  enum share_type: {
    cart_abandonment: 1,
    past_order: 2
    # user_share:  10,
    # marketing: 20
  }

  validates :share_type, inclusion: { in: share_types.keys }, presence: true

  delegate :code, to: :coupon, prefix: true, allow_nil: true

  #-----------------------------------------------------
  # Class methods
  #-----------------------------------------------------

  # TODO: consider splitting the building and creating logic out into build_from_order and create_from_order
  def self.create_from_order(order, share_type = :cart_abandonment)
    return if order.contains_digital_shipments? # Discussed with MB: No cart shares for digital-related orders, even if mixed
    return if order.shipping_methods.map(&:shipping_type).uniq == ['pickup'] # pickup orders don't have ship address

    raise UnableToCreateShareWithoutAddressError, 'Order does not have a shipping address.' unless order.ship_address
    raise UnableToCreateShareWithoutItemsError, 'Order does not have order items.' unless order.order_items.exists?

    # build model
    cart_share = CartShare.new(attrs_from_order(order))
    cart_share.share_type = share_type

    # build items
    share_items = order.order_items.map { |order_item| CartShareItem.build_from_order_item(order_item) }
    cart_share.cart_share_items = share_items

    # build address
    sanitized_address = order.ship_address&.dup_sanitized
    sanitized_address.name = 'Cart Share'
    sanitized_address.address_purpose = :cart_share
    cart_share.address = sanitized_address

    cart_share.save
    cart_share
  end

  def self.attrs_from_order(order)
    {
      user_id: order.user_id,
      order_id: order.id
    }
  end

  #-----------------------------------------------------
  # Instance methods
  #-----------------------------------------------------

  def get_items_for_suppliers(supplier_ids)
    purchasable_share_items = cart_share_items.map do |share_item|
      purchasable_variant = Variant.find_variant_for_suppliers(share_item.variant&.id, supplier_ids)
      addable_item_quantity = purchasable_variant.quantity_cart_addable(share_item.quantity) if purchasable_variant

      { variant: purchasable_variant, quantity: addable_item_quantity } if purchasable_variant && addable_item_quantity.positive?
    end

    purchasable_share_items.compact
  end

  def preferred_supplier_ids
    cart_share_items
      .joins(:variant)
      .pluck('variants.supplier_id')
      .uniq
  end
end
