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
#
# Indexes
#
#  index_carts_on_promo_code_id  (promo_code_id)
#  index_carts_on_storefront_id  (storefront_id)
#  index_carts_on_user_id        (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (promo_code_id => coupons.id)
#  fk_rails_...  (storefront_id => storefronts.id)
#

class ProductCart < Cart
  has_many :product_cart_items, foreign_key: :cart_id

  #------------------------------------------------------------
  # Instance methods
  #------------------------------------------------------------
  def add_product(product, qty = 1)
    item = product_cart_items.find_by(product_id: product.id)
    if item.present?
      item.update(quantity: (item.quantity + qty))
    else
      product_cart_items.create(product_id: product.id,
                                quantity: qty)
    end
  end

  def convert_to_standard_cart(address, supplier_ids)
    product_ids = product_cart_items.pluck(:product_id)

    delivery_zones = DeliveryZone.active.containing(address)
    shipping_methods = ShippingMethod.includes(:supplier).active.joins(:delivery_zones).merge(delivery_zones)

    bss = BestSupplierService.new(
      address: address,
      shipping_methods: shipping_methods,
      product_ids: product_ids
    )

    product_cart_items.each do |product_item|
      product_id = product_item.product_id
      suppliers = product_item.product.variants.where(supplier_id: supplier_ids).includes(:supplier).map(&:supplier).flatten
      best_suppliers = bss.best_supplier(suppliers)
      best_supplier = best_suppliers.first if best_suppliers.any?

      variant = Variant.active.find_by(product_id: product_item.product_id, supplier_id: best_supplier.id)
      add_item(variant.id, variant.id, nil, product_item.quantity) if variant
    end

    update_attribute('type', nil)
  end
end
