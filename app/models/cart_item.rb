# == Schema Information
#
# Table name: cart_items
#
#  id                 :integer          not null, primary key
#  user_id            :integer
#  cart_id            :integer
#  variant_id         :integer          not null
#  quantity           :integer          default(1)
#  active             :boolean          default(TRUE), not null
#  item_type_id       :integer          not null
#  created_at         :datetime
#  updated_at         :datetime
#  item_options_id    :integer
#  identifier         :decimal(, )      not null
#  product_bundle_id  :string
#  customer_placement :integer          default("standard")
#
# Indexes
#
#  index_cart_items_on_cart_id                 (cart_id)
#  index_cart_items_on_cart_id_and_identifier  (cart_id,identifier)
#  index_cart_items_on_item_options_id         (item_options_id)
#  index_cart_items_on_product_bundle_id       (product_bundle_id)
#  index_cart_items_on_variant_id              (variant_id)
#

# To understand this model more please look at the documentation in the CART.rb model
class CartItem < ActiveRecord::Base
  extend StringHashable

  belongs_to :cart, touch: true
  belongs_to :item_type
  belongs_to :item_options, class_name: 'ItemOptions', dependent: :destroy
  belongs_to :user
  belongs_to :variant
  belongs_to :product_bundle, optional: true

  has_one :supplier, through: :variant

  validates :item_type_id, presence: true
  validates :variant, presence: true
  validates :identifier, presence: true

  before_save :inactivate_zero_quantity

  # Call this if you need to know the unit price of an item
  #
  # @param [none]
  # @return [Float] price of the variant in the cart
  delegate :supplier_id, :supplier_name, to: :variant, allow_nil: true

  # TODO: find better way to do the invalid scope. going to get messy without an or operator
  scope :valid, -> { joins(:variant).merge(Variant.active.available) }
  scope :inactive_variant, -> { joins(:variant).merge(Variant.where.not(deleted_at: nil, product_active: true)) }
  scope :not_on_backorder, -> { where.not(customer_placement: customer_placements[:back_order]) }
  scope :invalid, -> { where('cart_items.id not in (?)', CartItem.valid.pluck(:id)) }

  scope :available_from_suppliers, lambda { |supplier_ids = []|
    joins(:variant).where('variants.supplier_id in (?)', supplier_ids)
  }
  scope :unavailable_from_suppliers, lambda { |supplier_ids = []|
    joins(:variant).where.not('variants.supplier_id in (?)', supplier_ids)
  }

  scope :active, -> { where(active: true) }
  scope :with_views, -> { includes(variant: { product_grouping_variant_store_view: :grouping_view }) }
  scope :distinct_items, -> { select('DISTINCT ON (cart_items.identifier) cart_items.*') }
  scope :active_suppliers, -> { joins(:supplier).merge(Supplier.active) }

  enum customer_placement: { standard: 0, pre_sale: 1, back_order: 2 }
  validates :customer_placement, inclusion: { in: customer_placements.keys }

  def name
    variant.product_name
  end

  def invalid?
    variant.inactive? || variant.sold_out?
  end

  def inactive_variant?
    variant.deleted_at.present? || !variant.product_active?
  end

  def price
    options_price = item_options.price if item_options.present? && variant.overridable?
    variant_price = variant.price if variant.present?
    options_price || variant_price
  end

  def quantity
    options_quantity = item_options.quantity if item_options.present?
    options_quantity || self[:quantity]
  end

  # Call this method if you need the price of an item before taxes
  #
  # @param [none]
  # @return [Float] price of the variant in the cart times quantity
  def total
    price * quantity
  end

  # Call this method to soft delete an item in the cart
  #
  # @param [none]
  # @return [Boolean]
  def inactivate!
    update(active: false)
  end

  # Call this method to determine if an item is in the shopping cart and active
  #
  # @param [none]
  # @return [Boolean]
  def shopping_cart_item?
    item_type_id == ItemType::SHOPPING_CART_ID && active?
  end

  def self.before(at)
    where('cart_items.created_at <= ?', at)
  end

  def storefront_specific_price
    BusinessVariantPriceService.new(
      variant.price,
      variant.real_price,
      variant.supplier.id,
      cart.storefront.business,
      variant
    ).call
  end

  def self.generate_identifier(options, type, variant_id)
    value = if options && type == 2
              "#{variant_id}:#{options[:line1]}:#{options[:line2]}"
            elsif options && type == 1
              [variant_id, options[:recipients] || [], options[:sender]].compact.join(':')
            else
              variant_id.to_s
            end
    string_hash_code(value)
  end

  private

  def inactivate_zero_quantity
    active = false if quantity.zero?
    true
  end
end
