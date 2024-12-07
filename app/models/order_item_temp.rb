# == Schema Information
#
# Table name: order_items
#
#  id                :integer          not null, primary key
#  price             :decimal(8, 2)
#  total             :decimal(8, 2)
#  variant_id        :integer          not null
#  tax_rate_id       :integer
#  shipment_id       :integer
#  created_at        :datetime
#  updated_at        :datetime
#  quantity          :integer          default(1)
#  sale_item         :boolean          default(FALSE), not null
#  tax_address_id    :integer
#  tax_charge        :decimal(8, 2)
#  substitute_id     :integer
#  item_options_id   :integer
#  bottle_deposits   :decimal(8, 2)    default(0.0)
#  identifier        :decimal(, )      not null
#  product_bundle_id :string
#
# Indexes
#
#  index_order_items_on_created_at                  (created_at)
#  index_order_items_on_item_options_id             (item_options_id)
#  index_order_items_on_product_bundle_id           (product_bundle_id)
#  index_order_items_on_shipment_id                 (shipment_id)
#  index_order_items_on_shipment_id_and_identifier  (shipment_id,identifier)
#  index_order_items_on_variant_id                  (variant_id)
#

class OrderItemTemp < OrderItem
  has_one :substitution, foreign_key: 'substitute_id'
  has_one :substitution, foreign_key: 'remaining_item_id'

  def skip_shipment_validation?
    true
  end
end
