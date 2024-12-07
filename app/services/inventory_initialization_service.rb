class InventoryInitializationService
  class << self
    def add_beers(supplier)
      beer_type = ProductType.find_by(name: 'beer')
      add_products_of_category(supplier, beer_type.id)
    end

    private

    def add_products_of_category(supplier, category_id)
      Supplier.find_by(permalink: 'inventory-template-store').variants.active
              .joins(product: [:product_size_grouping]).where(product_groupings: { hierarchy_category_id: category_id })
              .find_each do |variant|
        # Do not add variant if already in supplier's inventory
        next if supplier.variants.find_by(sku: variant.sku)
        next if variant.product.variants.find_by(supplier_id: supplier.id)

        # Add variant now
        new_variant = variant.dup
        new_variant.supplier_id = supplier.id
        new_variant.create_inventory(count_on_hand: 0)
        new_variant.save
      end
    end
  end
end
