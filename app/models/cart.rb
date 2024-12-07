# == Schema Information
#
# Table name: carts
#
#  id                        :integer          not null, primary key
#  user_id                   :integer
#  created_at                :datetime
#  updated_at                :datetime
#  doorkeeper_application_id :integer
#  type                      :string
#  storefront_id             :integer          not null
#  storefront_cart_id        :string
#  promo_code_id             :integer
#  address_id                :bigint(8)
#
# Indexes
#
#  index_carts_on_address_id     (address_id)
#  index_carts_on_promo_code_id  (promo_code_id)
#  index_carts_on_storefront_id  (storefront_id)
#  index_carts_on_user_id        (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (address_id => addresses.id)
#  fk_rails_...  (promo_code_id => coupons.id)
#  fk_rails_...  (storefront_id => storefronts.id)
#

class Cart < ActiveRecord::Base
  include TempStorefrontDefault

  belongs_to :customer, class_name: 'User'
  belongs_to :doorkeeper_application, class_name: 'Doorkeeper::Application'
  belongs_to :user
  belongs_to :storefront
  belongs_to :promo_code, class_name: 'Coupon'

  has_one :order
  has_one :cart_trait
  has_one :cart_amount, dependent: :destroy
  has_one :address, as: :addressable, dependent: :destroy

  has_many :cart_items
  has_many :shopping_cart_items, -> { where(active: true, item_type_id: ItemType::SHOPPING_CART_ID) }, class_name: 'CartItem'
  has_many :saved_cart_items, -> { where(active: true, item_type_id: ItemType::SAVE_FOR_LATER_ID) }, class_name: 'CartItem'
  has_many :purchased_items, -> { where(active: true, item_type_id: ItemType::PURCHASED_ID) }, class_name: 'CartItem'
  has_many :deleted_cart_items, -> { where(active: false) }, class_name: 'CartItem'

  has_many :cart_coupons
  has_many :gift_cards, through: :cart_coupons, source: :coupon

  accepts_nested_attributes_for :shopping_cart_items
  accepts_nested_attributes_for :cart_trait

  # Adds all the item prices (not including taxes) that are currently in the shopping cart
  #
  # @param [none]
  # @return [Float] This is a float in decimal form and represents the price of all the items in the cart
  def sub_total
    shopping_cart_items.map(&:total).sum
  end

  # Adds the quantity of items that are currently in the shopping cart
  #
  # @param [none]
  # @return [Integer] Quantity all the items in the cart
  def number_of_shopping_cart_items
    shopping_cart_items.map(&:quantity).sum
  end

  # Call this method when you want to add an item to the shopping cart
  #
  # @param [Integer, #read] cart item identifier
  # @param [Integer, #read] variant id to add to the cart
  # @param [User, #read] user that is adding something to the cart
  # @param [Integer, #optional] ItemType id that is being added to the cart
  # @return [CartItem] return the cart item that is added to the cart
  def add_item(item, cart_item_type_id = ItemType::SHOPPING_CART_ID, use_safe_qty_pad = true)
    items = shopping_cart_items.where(identifier: item[:identifier]).to_a
    variant = Variant.find_by(id: item[:variant_id])

    raise CartError::VariantNotFound, "Variant #{variant_id} not found" if variant.nil?

    quantity_to_purchase = variant.quantity_cart_addable(item[:quantity] || 1, use_safe_qty_pad)
    item_options = if variant.product.pre_engraved_message.present?
                     EngravingOptions.new(line1: variant.product.pre_engraved_message)
                   else
                     variant.read_options(item[:item_options])
                   end

    # TODO: LD: the if code branche is suspect
    if variant.sold_out?
      saved_cart_items.create(identifier: item[:identifier],
                              variant_id: variant.id,
                              user: item[:user],
                              item_type_id: ItemType::SAVE_FOR_LATER_ID,
                              quantity: item[:quantity] || 1,
                              item_options: item_options,
                              customer_placement: item[:customer_placement] || 0,
                              product_bundle: item[:product_bundle]) # ,#price: variant.price if items.size < 1
    else
      add_cart_items(items: items,
                     quantity: quantity_to_purchase,
                     user: item[:user],
                     cart_item_type_id: cart_item_type_id,
                     identifier: item[:identifier],
                     variant_id: variant.id,
                     item_options: item_options,
                     customer_placement: item[:customer_placement] || 0,
                     product_bundle: item[:product_bundle])
    end
  end

  # Call this method when you want to remove an item from the shopping cart
  #   The CartItem will not delete.  Instead it is just inactivated
  #
  # @param [Integer, #read] cart item identifier
  # @return [CartItem] return the cart item that is added to the cart
  def remove_item(identifier)
    cart_items.each { |ci| ci.inactivate! if identifier.to_i == ci.identifier }
  end

  def empty_cart!
    cart_items.each(&:destroy)
  end

  # TODO: now that we have get_variant_for_suppliers on variant, we can "smart diff" this
  def remove_invalid_items!(supplier_ids = [], use_in_stock_check = true)
    remove_items = if use_in_stock_check
                     cart_items.active.includes(:variant).filter(&:invalid?).to_a
                   else
                     cart_items.active.includes(:variant).not_on_backorder.filter(&:inactive_variant?).to_a
                   end
    remove_items.concat(cart_items.active.unavailable_from_suppliers(supplier_ids).to_a) if supplier_ids&.any?
    remove_items.each(&:inactivate!)
  end

  # Call this method when you want to associate the cart with a user
  #
  # @param [User]
  def save_user(user)
    if user && user_id != user.id
      self.user_id = user.id
      save
    end
  end

  # Call this method when you want to mark the items in the order as purchased
  #   The CartItem will not delete.  Instead the item_type changes to purchased
  #
  # @param [Order]
  def mark_items_purchased(order)
    cart_items.where(variant_id: order.variant_ids).update_all(item_type_id: ItemType::PURCHASED_ID)
  end

  def skip_in_stock_check
    !storefront.enable_in_stock_check
  end

  def update_amounts
    self.cart_amount = Carts::CartAmountService.new(self).call if Feature[:enable_cart_amounts].enabled?
  end

  private

  def update_shopping_cart(cart_item, customer, qty = 1)
    if customer
      shopping_cart_items.find(cart_item.id).update(quantity: (cart_item.quantity + qty), user_id: customer.id)
    else
      shopping_cart_items.find(cart_item.id).update(quantity: (cart_item.quantity + qty))
    end
  end

  def add_cart_items(params)
    if params[:items].empty?
      cart_item = shopping_cart_items.create(identifier: params[:identifier],
                                             variant_id: params[:variant_id],
                                             user: params[:user],
                                             item_type_id: params[:cart_item_type_id],
                                             quantity: params[:quantity],
                                             item_options: params[:item_options],
                                             product_bundle: params[:product_bundle],
                                             customer_placement: params[:customer_placement] || 0) # ,#price: variant.price
    else
      cart_item = params[:items].first
      update_shopping_cart(cart_item, params[:user], params[:quantity])
    end
    cart_item
  end
end
