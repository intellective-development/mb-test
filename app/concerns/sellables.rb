module Sellables
  extend ActiveSupport::Concern

  included do
    helper_method :sellable_types,
                  :sellable_name
  end

  protected

  def sellable_types
    # [['Supplier', 'Supplier'], ['Product', 'Variant'], ['Brand', 'Brand'], ['ProductType', 'ProductType']]
    [%w[All All], %w[Supplier Supplier], %w[ProductType ProductType], %w[Brand Brand], %w[Product Product]]
  end

  # Used on coupon show page
  def sellable_name(model)
    case model
    when ProductType
      model.name
    when Supplier
      model.name
    when Brand
      model.name
    when Product
      model.name
    when Variant
      model.product_name
    else
      "#{model.class}: #{model.id}"
    end
  end
end
