# We may have special pricing rules defined for specific business/supplier combination
class BusinessVariantPriceService
  include CriticalWarning

  attr_reader :price, :real_price, :supplier_id, :business, :variant

  # @param price - sale_price of item, or real_price if no sale_price is specified
  #   (actually this should be a value from product_grouping_suppliers_variants.price column)
  # @param real_price - original price of item
  # @param supplier_id - id of supplier
  # @param business - business
  def initialize(price, real_price, supplier_id, business, variant)
    @price = price
    @real_price = real_price
    @supplier_id = supplier_id
    @business = business
    @variant = variant

    if @business.nil?
      message = 'Business object must be provided for BusinessVariantPriceService'
      if Rails.env.production?
        # In production we send warning to Sentry and fallback to minibar prices
        critical_warning(message)
      else
        # In test and development we raise an exception to easily detect problem
        raise message
      end
    end
  end

  def call
    return price if business.nil? || variant&.gift_card?

    unless Business.default_business?(business.id)
      pre_sale = PreSale.find_available(variant&.product_id, supplier_id)
      return pre_sale.price if pre_sale.present?

      business_supplier = BusinessSupplier.find_by(supplier_id: supplier_id, business: business)
      if business_supplier
        value = real_price * (1 + (business_supplier.percent_markup.to_f / 100.0)) + business_supplier.amount_markup.to_f
        return business.round(value)
      end
    end

    price
  end
end
