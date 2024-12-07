module Admin::BusinessVariantPriceServiceHelper
  def business_variant_price(price, real_price, supplier_id, business, variant)
    BusinessVariantPriceService.new(
      price,
      real_price,
      supplier_id,
      business,
      variant
    ).call
  end
end
