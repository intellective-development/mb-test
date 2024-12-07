# == Schema Information
#
# Table name: coupon_items
#
#  id        :integer          not null, primary key
#  item_id   :integer          not null
#  item_type :string(255)      not null
#  coupon_id :integer
#
# Indexes
#
#  index_coupon_items_on_coupon_id  (coupon_id)
#
# Foreign Keys
#
#  fk_rails_...  (coupon_id => coupons.id)
#

class CouponItem < ActiveRecord::Base
  belongs_to :coupon, inverse_of: :coupon_items
  belongs_to :item, polymorphic: true

  validates :coupon, :item, presence: true

  delegate :sellable_restriction_excludes, to: :coupon

  def matches_restriction_rules?(order)
    match_order_item = order.shipments.map do |shipment|
      shipment.order_items.any? do |order_item|
        check_order_item(order_item)
      end
    end

    # if the coupon has the exclusion rule on, we want to make it true if its false
    # the logic here is somewhat not intuitive. in regards to sellable_restriction_excludes:
    #   - when is false we have a restriction rule, so we want matches. we then check for true (matches)
    #   - when is true its an exclusion rule, we don't want matches. we then check for false
    # that is why we negate sellable_restriction_excludes
    match_order_item.include? !sellable_restriction_excludes
  end

  def qualified?(order)
    order.shipments.any? do |shipment|
      shipment.order_items.any? do |order_item|
        check_order_item(order_item)
      end
    end
  end

  def find_variant_ids
    variant_ids_for = ->(product_ids) { Variant.active.where('product_id IN (?)', product_ids).pluck(:id) }
    case item
    when Variant
      [item.id]
    when Supplier
      supplier_ids = [item.id] + item.get_child_supplier_ids
      Variant.active.where(supplier_id: supplier_ids).select('id').pluck(:id)
    when ProductType
      product_ids = ProductType.find(item.id).self_and_descendants.flat_map { |pt| pt.products.pluck(:id) }
      variant_ids_for[product_ids]
    when Brand
      product_ids = Product.joins(:brand).where('brands.id = ? OR brands.parent_brand_id = ?', item.id, item.id).pluck(:id)
      variant_ids_for[product_ids]
    when Product
      product_ids = [item.id]
      variant_ids_for[product_ids]
    else
      []
    end
  end

  private

  def check_order_item(order_item)
    case item
    when Supplier
      supplier_ids = [item.id] + item.get_child_supplier_ids
      supplier_ids.include?(order_item.variant.supplier_id)
    when Brand
      order_item.variant.brand&.id == item.id || order_item.variant.brand&.parent_brand_id == item.id
    when Variant
      order_item.variant.id == item.id
    when ProductType
      order_item.variant.product_type.id == item.id
    when Product
      order_item.variant.product_id == item.id
    end
  end
end
