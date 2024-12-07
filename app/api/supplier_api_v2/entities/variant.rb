class SupplierAPIV2::Entities::Variant < Grape::Entity
  format_with(:price_formatter) { |value| value&.to_f&.round_at(2) }

  expose :active?, as: :active
  expose :case_eligible
  expose :count_on_hand, as: :inventory, safe: true
  expose :id
  expose :item_volume, as: :volume, safe: true
  expose :name, safe: true
  expose :sku

  with_options(format_with: :price_formatter) do
    expose :original_price, as: :price
    expose :sale_price
  end

  expose :category, safe: true do |variant|
    variant.product_type&.ancestry_path&.join(' | ')
  end

  expose :not_owned do |variant, options|
    variant.supplier_id != options[:current_supplier].id if options&.key?(:current_supplier)
  end

  expose :product_state, safe: true do |variant|
    variant.product&.state
  end
end
