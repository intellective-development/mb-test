# == Schema Information
#
# Table name: inventories
#
#  id                        :integer          not null, primary key
#  count_on_hand             :integer          default(0)
#  count_pending_to_customer :integer          default(0)
#  variant_id                :integer
#
# Indexes
#
#  idx_inventories_quantity  (((count_on_hand - count_pending_to_customer)))
#

# We keep inventory in a separate table for performance reasons since we rely on
# pessimistic locking during low-stock scenarios.
#
# As of August 2016, we do not tend to use the count_pending_to_customer column,
# due to the sequencing of the checkout process. We may wish to resurrect this
# functionality in future for high demand, limited availability items.
#
# This model is responsible for broadcasting in_stock? state changes, this event
# can be used to trigger indexing of parent model(s) and/or other notifications.
class Inventory < ActiveRecord::Base
  include Wisper::Publisher

  OUT_OF_STOCK_QTY = 2
  LOW_STOCK_QTY    = 6

  has_one :variant

  validates :count_on_hand, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 999_999_999_999,
    only_integer: true
  }
  validates :count_pending_to_customer, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 999_999_999_999,
    only_integer: true
  }

  delegate :price, to: :variant, allow_nil: true, prefix: true

  before_validation :ensure_valid_count_on_hand, if: :count_on_hand_changed?
  before_validation :ensure_valid_count_pending_to_customer, if: :count_pending_to_customer_changed?
  before_save :zero_if_variant_price_zero
  before_save :ensure_variant_id
  after_save :check_in_stock_status

  #-----------------------------------------------------
  # Scopes
  #-----------------------------------------------------
  scope :available, -> { where('inventories.count_on_hand - inventories.count_pending_to_customer > ?', OUT_OF_STOCK_QTY) }
  scope :unavailable, -> { where('inventories.count_on_hand - inventories.count_pending_to_customer <= ?', OUT_OF_STOCK_QTY) }

  #-----------------------------------------------------
  # Instance methods
  #-----------------------------------------------------
  def reduce_by(num)
    lock! if low_stock?
    update_attribute :count_on_hand, count_on_hand - Integer(num)
  end

  def sold_out?
    quantity_available <= OUT_OF_STOCK_QTY
  end

  def low_stock?
    quantity_available <= LOW_STOCK_QTY
  end

  def quantity_purchaseable(use_safe_qty_pad = true)
    (quantity_available - (use_safe_qty_pad ? Inventory::OUT_OF_STOCK_QTY : 0))
  end

  def quantity_available
    return 0 unless count_on_hand

    count_on_hand - count_pending_to_customer
  end

  private

  def in_stock?(count, pending)
    (count - pending) > OUT_OF_STOCK_QTY
  end

  def check_in_stock_status
    if in_stock_changed?
      variant&.reindex_async
      variant&.product&.reindex_async
      variant&.product&.product_size_grouping&.reindex_async
    end
  end

  def ensure_valid_count_on_hand
    self.count_on_hand = count_on_hand.negative? ? 0 : Integer(count_on_hand)
  end

  def ensure_valid_count_pending_to_customer
    self.count_pending_to_customer = count_pending_to_customer.negative? ? 0 : Integer(count_pending_to_customer)
  end

  def zero_if_variant_price_zero
    self.count_on_hand = 0 if variant && variant_price.to_f.zero?
    true
  end

  def in_stock_changed?
    in_stock?(count_on_hand_was, count_pending_to_customer_was) != in_stock?(count_on_hand, count_pending_to_customer)
  end

  def ensure_variant_id
    self.variant_id = variant&.id
  end
end
